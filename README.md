# Helm Charts

This repository contains independent Helm charts:

- `postgres` — PostgreSQL standalone or streaming replication
- `redis` — Redis standalone or Redis Cluster
- `clickhouse` — ClickHouse standalone or sharded cluster with Keeper
- `kafka` — Apache Kafka in KRaft mode (no ZooKeeper)
- `mongodb` — MongoDB standalone or replica set
- `mysql` — MySQL standalone or GTID-based primary-replica
- `rabbitmq` — RabbitMQ standalone or clustered via Erlang distribution
- `otel` — OpenTelemetry Collector (Deployment)
- `langfuse` — Langfuse LLM observability platform
- `sentry` — Sentry 26.x error tracking and performance monitoring
- `opensearch` — OpenSearch standalone or clustered with security
- `tempo` — Grafana Tempo tracing backend

Each chart owns its own templates, values, Secrets, Services, and StatefulSets.
They do not depend on each other.

When password values are left empty, charts that manage credentials generate strong Kubernetes Secret values on first install and reuse them on upgrade with Helm `lookup`. For production GitOps, prefer `existingSecret` or explicit values sourced from a secret manager so credentials are controlled outside the Helm release manifest.

## Production Profiles

Each chart has a `values-production.yaml` example with larger resources, retained PVCs, external Secret references, and production-oriented cluster settings:

```bash
helm upgrade --install <release> ./<chart> -f ./<chart>/values-production.yaml
```

These files are intentionally examples, not blind defaults. Replace every placeholder StorageClass, Secret name, public URL, object-store endpoint, TLS secret, and dependency hostname before using them in a real environment.

Monitoring is conservative by default. `ServiceMonitor` is enabled only where the chart itself exposes a known metrics endpoint, such as OpenTelemetry Collector, Tempo, and ClickHouse with `metrics.enabled=true`. For PostgreSQL, Redis, MongoDB, MySQL, RabbitMQ, Kafka, OpenSearch, Sentry, and Langfuse, add the appropriate exporter/plugin or verified metrics endpoint before enabling their `serviceMonitor` values.

Tempo remains a monolithic chart. The production profile uses S3 and a larger single replica; for very high ingest volume or horizontal scaling, use a distributed Tempo deployment instead of increasing `replicaCount` on this chart.

## PostgreSQL

```bash
# Standalone
helm install pg ./postgres

# Cluster: one primary + two read replicas
helm install pg ./postgres --set cluster.enabled=true --set cluster.replicas=3
```

## Redis

```bash
# Standalone
helm install redis ./redis

# Redis Cluster: 3 masters + 1 replica each
helm install redis ./redis --set cluster.enabled=true
```

## ClickHouse

```bash
# Standalone
helm install ch ./clickhouse

# Cluster with 2 shards, 2 replicas per shard, and Keeper
helm install ch ./clickhouse \
  --set cluster.enabled=true \
  --set cluster.shards=2 \
  --set cluster.replicasPerShard=2 \
  --set keeper.enabled=true \
  --set keeper.replicas=3
```

## Kafka

Kafka runs in KRaft mode without ZooKeeper.

```bash
# Default (3 brokers)
helm install kafka ./kafka

# With SASL authentication
helm install kafka ./kafka \
  --set auth.enabled=true \
  --set 'auth.clientUsers[0].user=admin' \
  --set 'auth.clientUsers[0].password=<strong-random-password>'
```

## MongoDB

The chart defaults to MongoDB 7.0 for compatibility with Linux 6.19+ kernels.

```bash
# Standalone
helm install mongodb ./mongodb

# Replica set with 3 members
helm install mongodb ./mongodb \
  --set cluster.enabled=true \
  --set cluster.members=3
```

## MySQL

```bash
# Standalone
helm install mysql ./mysql

# Primary-replica with 1 primary + 2 replicas
helm install mysql ./mysql \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

## RabbitMQ

```bash
# Standalone
helm install rabbitmq ./rabbitmq

# Cluster with 3 nodes
helm install rabbitmq ./rabbitmq \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

## OpenTelemetry Collector

```bash
# Standalone
helm install otel ./otel

# Export to a backend
helm install otel ./otel \
  --set config.exporters.otlp.endpoint=tempo.default.svc.cluster.local:4317 \
  --set config.exporters.otlp.tls.insecure=true \
  --set 'config.service.pipelines.traces.exporters[1]=otlp'
```

## Langfuse

Langfuse needs PostgreSQL, ClickHouse, and Redis as external dependencies.

```bash
helm install langfuse ./langfuse \
  --set auth.nextauthUrl=https://langfuse.example.com \
  --set postgres.host=postgres \
  --set postgres.password=<pg-password> \
  --set clickhouse.url=http://clickhouse:8123 \
  --set clickhouse.password=<ch-password> \
  --set redis.connectionString=redis://:password@redis:6379/0
```

## Sentry

Sentry 26.x needs PostgreSQL, Redis, ClickHouse, and Kafka as external dependencies.

```bash
helm install sentry ./sentry \
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

## OpenSearch

```bash
# Standalone
helm install os ./opensearch

# Cluster with 3 nodes
helm install os ./opensearch --set cluster.enabled=true --set cluster.replicas=3

# Disable security (development only)
helm install os ./opensearch --set security.disabled=true

# Production TLS: do not use bundled demo certificates
helm install os ./opensearch \
  --set security.useDemoCerts=false \
  --set security.tls.existingSecret=os-tls \
  --set 'security.tls.adminDn[0]=CN=admin' \
  --set 'security.tls.nodesDn[0]=CN=opensearch'
```

## Tempo

```bash
helm install tempo ./tempo

# Use object storage for production retention beyond local disk
helm install tempo ./tempo \
  --set storage.backend=s3 \
  --set storage.s3.bucket=tempo-traces \
  --set storage.s3.endpoint=https://s3.amazonaws.com \
  --set storage.s3.region=us-east-1 \
  --set storage.s3.existingSecret=tempo-s3
```

## Validation

```bash
for d in */; do helm lint "$d" && helm template test "$d" >/dev/null; done
for d in */; do [ -f "$d/values-production.yaml" ] && helm template prod "$d" -f "$d/values-production.yaml" >/dev/null; done

helm template pg ./postgres
helm template redis ./redis
helm template ch ./clickhouse
helm template kafka ./kafka
helm template mongodb ./mongodb
helm template mysql ./mysql
helm template rabbitmq ./rabbitmq
helm template otel ./otel
helm template langfuse ./langfuse
helm template sentry ./sentry
helm template os ./opensearch
helm template tempo ./tempo
```
