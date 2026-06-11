# ClickHouse Helm Chart

This chart deploys ClickHouse in standalone mode or cluster mode. Cluster mode can deploy a separate ClickHouse Keeper StatefulSet for replicated tables and distributed DDL.

## Quick Start

```bash
helm install ch ./clickhouse
```

## Modes

### Standalone

Standalone mode is the default. It creates one ClickHouse StatefulSet, one client Service, one headless Service, one Secret unless `auth.existingSecret` is set, one ConfigMap, and one PVC per pod.

### Cluster Mode With Standalone Keeper

Cluster mode creates:

- one ClickHouse server StatefulSet with `cluster.shards * cluster.replicasPerShard` pods
- one ClickHouse Keeper StatefulSet with `keeper.replicas` pods when `keeper.enabled=true`
- a headless Keeper Service exposing the Keeper client and raft ports

Example with 2 shards, 2 replicas per shard, and 3 Keeper pods:

```bash
helm install ch ./clickhouse \
  --set cluster.enabled=true \
  --set cluster.shards=2 \
  --set cluster.replicasPerShard=2 \
  --set keeper.enabled=true \
  --set keeper.replicas=3
```

This creates 4 ClickHouse server pods and 3 `clickhouse-keeper` pods.

If your cluster cannot pull from Docker Hub reliably, override the images, for example:

```bash
helm install ch ./clickhouse \
  --set cluster.enabled=true \
  --set cluster.shards=2 \
  --set cluster.replicasPerShard=2 \
  --set keeper.enabled=true \
  --set keeper.replicas=3 \
  --set image.repository=docker.1ms.run/clickhouse/clickhouse-server \
  --set image.tag=26.3.10.60-alpine \
  --set keeper.image.repository=docker.1ms.run/clickhouse/clickhouse-keeper \
  --set keeper.image.tag=26.3.10.60-alpine
```

## Keeper Notes

Keeper is not embedded in the ClickHouse server pods. It runs as a separate StatefulSet using the `clickhouse-keeper` process.

ClickHouse server configuration still uses the XML tag `<zookeeper>` to list coordination endpoints. In this chart, those endpoints point to ClickHouse Keeper pods, not to a ZooKeeper deployment.

Keeper health check example:

```bash
kubectl exec -n <namespace> <release>-clickhouse-keeper-0 -c keeper -- \
  sh -ec 'printf ruok | nc -w 2 127.0.0.1 9181'
```

Expected output:

```text
imok
```

## Cluster Verification

List the configured ClickHouse topology:

```bash
kubectl exec -n <namespace> <release>-clickhouse-0 -- \
  clickhouse-client --user default --password <password> \
  --query "SELECT cluster, shard_num, replica_num, host_name FROM system.clusters WHERE cluster='default' ORDER BY shard_num, replica_num"
```

Count all replicas:

```bash
kubectl exec -n <namespace> <release>-clickhouse-0 -- \
  clickhouse-client --user default --password <password> \
  --query "SELECT count() FROM clusterAllReplicas('default', system.one)"
```

For a 2 shard x 2 replica deployment, the count should be `4`.

## Important Values

| Value | Description | Default |
|---|---|---|
| `auth.user` | ClickHouse user | `default` |
| `auth.password` | ClickHouse password; empty generates and reuses a Secret value | `""` |
| `auth.existingSecret` | Use an existing Secret instead of rendering one | `""` |
| `cluster.enabled` | Enable cluster mode | `false` |
| `cluster.shards` | Number of shards | `1` |
| `cluster.replicasPerShard` | Replicas per shard | `3` |
| `keeper.enabled` | Deploy standalone ClickHouse Keeper | `true` |
| `keeper.replicas` | Number of Keeper pods | `3` |
| `persistence.enabled` | Create PVCs for ClickHouse data | `true` |
| `keeper.persistence.enabled` | Create PVCs for Keeper data | `true` |
| `configuration.maxConnections` | ClickHouse `max_connections` server setting | `4096` |
| `configuration.maxConcurrentQueries` | ClickHouse `max_concurrent_queries` server setting | `100` |
| `configuration.markCacheSize` | ClickHouse mark cache size in bytes | `4294967296` |
| `profiles.default.maxMemoryUsage` | Default profile per-query memory limit in bytes | `6000000000` |
| `metrics.enabled` | Enable native ClickHouse Prometheus endpoint | `false` |
| `resources` | ClickHouse CPU/memory requests and limits | `{requests: {cpu: 500m, memory: 2Gi}, limits: {cpu: 4, memory: 8Gi}}` |

## Security Notes

- Leave `auth.password` empty only if you want Helm to generate and then reuse the chart-managed Secret. For production GitOps, prefer `auth.existingSecret` or an explicit value sourced from a secret manager.
- ClickHouse and Keeper main containers run as non-root users by default.
- `volumePermissions` uses a short-lived root initContainer to set PVC ownership, then main containers run non-root.
- Service account token automount is disabled for ClickHouse server and Keeper pods.
- Add production-sized resource requests and limits based on workload needs.

## Cleanup

```bash
helm uninstall ch -n <namespace>
```

PVCs created by StatefulSets may remain after uninstall depending on the cluster and Kubernetes version.
