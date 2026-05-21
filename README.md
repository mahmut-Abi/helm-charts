# Helm Charts

This repository contains three independent Helm charts:

- `postgres`
- `redis`
- `clickhouse`

Each chart owns its own templates, values, Secrets, Services, and StatefulSets.
They do not depend on each other.

## PostgreSQL

Standalone mode is the default:

```bash
helm install pg ./postgres
```

Cluster mode creates one primary and streaming read replicas in a single
StatefulSet. Pod ordinal `0` is the primary.

```bash
helm install pg ./postgres \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

The normal Service points to the primary pod in cluster mode. The chart does
not perform automatic PostgreSQL failover.

## Redis

Standalone mode is the default:

```bash
helm install redis ./redis
```

Redis Cluster mode uses native Redis Cluster and initializes it with a Helm hook
Job.

```bash
helm install redis ./redis --set cluster.enabled=true
```

The default cluster layout is `3` masters with `1` replica per master, for `6`
pods total.

## ClickHouse

Standalone mode is the default:

```bash
helm install ch ./clickhouse
```

Cluster mode creates ClickHouse server pods with shard and replica macros,
remote server configuration, and a separate ClickHouse Keeper StatefulSet.

```bash
helm install ch ./clickhouse \
  --set cluster.enabled=true \
  --set cluster.shards=2 \
  --set cluster.replicasPerShard=2 \
  --set keeper.replicas=3
```

## Validation

```bash
helm lint postgres redis clickhouse
helm template pg ./postgres
helm template redis ./redis
helm template ch ./clickhouse
```
