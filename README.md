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

Each chart owns its own templates, values, Secrets, Services, and StatefulSets.
They do not depend on each other.

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
  --set auth.interBrokerPassword=changeme \
  --set 'auth.clientUsers[0].user=admin,auth.clientUsers[0].password=changeme'
```

## MongoDB

```bash
# Standalone
helm install mongodb ./mongodb --set auth.rootPassword=my-secret-pw

# Replica set with 3 members
helm install mongodb ./mongodb \
  --set auth.rootPassword=my-secret-pw \
  --set cluster.enabled=true \
  --set cluster.members=3
```

## MySQL

```bash
# Standalone
helm install mysql ./mysql --set auth.rootPassword=my-secret-pw

# Primary-replica with 1 primary + 2 replicas
helm install mysql ./mysql \
  --set auth.rootPassword=my-secret-pw \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

## RabbitMQ

```bash
# Standalone
helm install rabbitmq ./rabbitmq --set auth.defaultPass=my-secret-pw

# Cluster with 3 nodes
helm install rabbitmq ./rabbitmq \
  --set auth.defaultPass=my-secret-pw \
  --set auth.erlangCookie=shared-secret \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

## OpenTelemetry Collector

```bash
# Standalone
helm install otel ./otel

# Export to a backend
helm install otel ./otel \
  --set config.exporters.otlp.endpoint=tempo.default.svc.cluster.local:4317
```

## Langfuse

Langfuse needs PostgreSQL, ClickHouse, and Redis as external dependencies.

```bash
helm install langfuse ./langfuse \
  --set auth.salt=$(openssl rand -hex 16) \
  --set auth.encryptionKey=$(openssl rand -hex 32) \
  --set auth.nextauthSecret=$(openssl rand -hex 32) \
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

## OpenSearch

```bash
# Standalone
helm install os ./opensearch

# Cluster with 3 nodes
helm install os ./opensearch --set cluster.enabled=true --set cluster.replicas=3

# Disable security (development only)
helm install os ./opensearch --set security.disabled=true
```

## Validation

```bash
helm lint postgres redis clickhouse kafka mongodb mysql rabbitmq otel langfuse sentry opensearch
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
```