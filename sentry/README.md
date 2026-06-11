# Sentry Helm Chart

This chart deploys [Sentry](https://sentry.io), an open-source error tracking and performance monitoring platform. Sentry 26.x uses a task-based worker system with a gRPC taskbroker instead of Celery.

## Components

| Component | Workload | Purpose |
|---|---|---|
| **Web** | Deployment | Django + React frontend behind granian (port 9000) |
| **Worker** | Deployment | Task worker connected to taskbroker via gRPC |
| **Cron** | Deployment | Scheduled task runner (taskworker-scheduler) |
| **Relay** | Deployment | Event ingestion proxy — SDKs send events here (port 3000) |
| **Snuba API** | Deployment | ClickHouse query service for event search and aggregation |
| **Snuba Consumer** | Deployment | Kafka consumer that writes events to ClickHouse |
| **Taskbroker** | StatefulSet | gRPC task broker (port 50051) with persisted SQLite task state |
| **Upgrade Job** | Job | Runs `sentry upgrade --noinput` on install/upgrade, auto-creates databases |

## External Dependencies

This chart expects PostgreSQL, Redis, ClickHouse, and Kafka to be running externally. Use any companion chart from this repo:

| Dependency | Chart | Connection via |
|---|---|---|
| PostgreSQL | `./postgres` | `postgres.host` / `postgres.password` |
| Redis | `./redis` | `redis.host` / `redis.password` |
| ClickHouse | `./clickhouse` | `clickhouse.host` / `clickhouse.password` |
| Kafka | `./kafka` | `kafka.bootstrapServers` |

## Quick Start

First deploy the four dependencies, then install Sentry:

```bash
helm install sentry ./sentry \
  --set auth.secretKey=$(openssl rand -hex 32) \
  --set user.password=$(openssl rand -hex 16) \
  --set postgres.host=postgres \
  --set postgres.password=<pg-password> \
  --set redis.host=redis \
  --set redis.password=<redis-password> \
  --set kafka.bootstrapServers=kafka:9092 \
  --set clickhouse.host=clickhouse \
  --set clickhouse.password=<ch-password> \
  --set system.url=https://sentry.example.com
```

When the secret key is omitted, the chart auto-generates one via the Secret template.

### With Ingress

```bash
helm install sentry ./sentry \
  ... \
  --set ingress.enabled=true \
  --set ingress.hostname=sentry.example.com \
  --set ingress.tls[0].secretName=sentry-tls \
  --set ingress.tls[0].hosts[0]=sentry.example.com
```

### Enabling Kafka Topic Auto-Creation

The snuba-consumer needs Kafka topics to exist. Set `kafka.autoCreateTopics=true` (default) and the chart adds an init container that creates the required topics via `kafka-topics.sh`.

```bash
# Customize the topic list if needed
helm install sentry ./sentry \
  --set kafka.topics[0]=events \
  --set kafka.topics[1]=snuba-metrics
```

## Authentication and Admin User

The worker needs `--rpc-host` pointing at the taskbroker gRPC service. This is wired automatically: the taskbroker creates a headless service `<release>-sentry-taskbroker:50051` and the worker deployment passes that to `sentry run taskworker --rpc-host=<release>-sentry-taskbroker.<namespace>.svc.cluster.local:50051`.

Taskbroker stores inflight task state in SQLite. The chart keeps it as a single-replica StatefulSet and enables a 1Gi PVC by default. For short-lived test clusters without a StorageClass, set `taskbroker.persistence.enabled=false`.

The cron deployment runs `sentry run taskworker-scheduler` and does not connect to the taskbroker directly.

## Relay Initialization

The relay pod uses two init containers:

1. **copy-config**: copies (`cp`) relay config and credentials from a generated ConfigMap / Secret to an emptyDir at `/etc/relay`
2. **generate-creds**: runs `relay credentials generate` in `/etc/relay` to create the relay key pair used for upstream registration

The relay registers with the Sentry web upstream at `http://sentry.<namespace>.svc.cluster.local:9000/api/0/relays/register/challenge/`.

## Snuba

Snuba has two components — API and consumer. The consumer reads events from Kafka and writes them to ClickHouse. The API serves queries from the Sentry web frontend.

## Important Values

| Value | Description | Default |
|---|---|---|
| `image.sentry.tag` | Sentry image tag | `26.5.0` |
| `image.relay.tag` | Relay image tag | `26.5.0` |
| `image.snuba.tag` | Snuba image tag | `26.5.0` |
| `image.taskbroker.tag` | Taskbroker image tag | `26.5.0` |
| `auth.secretKey` | Django SECRET_KEY | auto-generated |
| `auth.existingSecret` | Use an existing Secret | `""` |
| `user.email` | Admin user email | `admin@sentry.local` |
| `user.password` | Admin user password | `""` |
| `postgres.host` | PostgreSQL hostname | `""` |
| `postgres.password` | PostgreSQL password | `""` |
| `redis.host` | Redis hostname | `""` |
| `redis.password` | Redis password | `""` |
| `kafka.bootstrapServers` | Kafka bootstrap servers | `""` |
| `kafka.autoCreateTopics` | Auto-create Kafka topics for snuba | `true` |
| `clickhouse.host` | ClickHouse hostname | `""` |
| `clickhouse.password` | ClickHouse password | `""` |
| `clickhouse.singleNode` | Use single-node ClickHouse settings | `true` |
| `clickhouse.clusterName` | ClickHouse cluster name used when `singleNode=false` | `default` |
| `filestore.backend` | File storage backend (`filesystem`, `s3`, or `gcs`) | `filesystem` |
| `filestore.s3.existingSecret` | Secret containing S3 filestore credentials | `""` |
| `system.url` | Public URL (email links, etc.) | `http://localhost:9000` |
| `service.type` | Web Service type | `ClusterIP` |
| `ingress.enabled` | Enable Ingress | `false` |
| `gateway.enabled` | Enable Gateway API HTTPRoute | `false` |
| `taskbroker.enabled` | Deploy the taskbroker | `true` |
| `taskbroker.kafkaTopic` | Taskbroker Kafka topic | `taskworker` |
| `taskbroker.persistence.enabled` | Persist taskbroker SQLite state | `true` |
| `upgrade.enabled` | Run revisioned migration/database setup job | `true` |
| `web.replicas` | Web pods | `1` |
| `worker.replicas` | Worker pods | `1` |
| `worker.concurrency` | Taskworker process concurrency per pod | `4` |
| `relay.replicas` | Relay pods | `1` |
| `snuba.api.replicas` | Snuba API pods | `1` |
| `snuba.consumer.replicas` | Snuba consumer pods | `1` |
| `snuba.consumer.resources` | Resources applied to each Snuba consumer container | requests set |

## Cleanup

```bash
helm uninstall sentry -n <namespace>
```

Manually clean up PVCs if filestore or taskbroker persistence was enabled:

```bash
kubectl delete pvc -n <namespace> -l app.kubernetes.io/instance=sentry
```
