# Redis Helm Chart

This chart deploys Redis in standalone mode or Redis Cluster mode.

## Modes

### Standalone

Standalone mode is the default. It creates one StatefulSet, one client Service, one headless Service, one Secret when auth is enabled and `auth.existingSecret` is not set, and one PVC per pod.

```bash
helm install redis ./redis
```

If `cluster.enabled=false`, increasing `replicaCount` creates multiple independent Redis pods. It does not configure Redis replication or Sentinel.

### Redis Cluster

Redis Cluster mode is enabled with:

```bash
helm install redis ./redis \
  --set cluster.enabled=true \
  --set cluster.masters=3 \
  --set cluster.replicasPerMaster=1
```

The pod count is calculated as:

```text
cluster.masters * (cluster.replicasPerMaster + 1)
```

With the default cluster values, the chart creates 6 pods: 3 masters and 1 replica per master.

A Helm hook Job named `<release>-cluster-init` waits for all pods and runs `redis-cli --cluster create ... --cluster-replicas <replicasPerMaster> --cluster-yes`. The hook Job is deleted after a successful run.

## Role Discovery

Redis Cluster roles are assigned by Redis at runtime. Pod names do not encode master or replica roles, and roles may change after failover.

Inspect the live role mapping with:

```bash
kubectl exec -n <namespace> <release>-0 -- \
  redis-cli -a <password> --no-auth-warning cluster nodes
```

Look for `master` and `slave <master-node-id>` in the output.

Check cluster health:

```bash
kubectl exec -n <namespace> <release>-0 -- \
  redis-cli -a <password> --no-auth-warning cluster info
```

Expected healthy markers include:

```text
cluster_state:ok
cluster_slots_assigned:16384
cluster_known_nodes:<pod count>
```

## Services and Ports

Standalone mode exposes Redis port `6379`.

Cluster mode also exposes the cluster bus port, default `16379`, on both the normal and headless Services. Redis Cluster announces stable StatefulSet DNS names so clients receive usable endpoints in MOVED and ASK responses.

## Important Values

| Value | Description | Default |
|---|---|---|
| `auth.enabled` | Enable password authentication | `true` |
| `auth.password` | Redis password | `change-me` |
| `auth.existingSecret` | Use an existing Secret instead of rendering one | `""` |
| `cluster.enabled` | Enable Redis Cluster mode | `false` |
| `cluster.masters` | Number of Redis Cluster masters | `3` |
| `cluster.replicasPerMaster` | Replicas per master | `1` |
| `cluster.initJob.enabled` | Run the cluster creation hook Job | `true` |
| `persistence.enabled` | Create PVCs for data | `true` |
| `resources` | Container CPU/memory requests and limits | `{requests: {cpu: 100m, memory: 128Mi}, limits: {cpu: 500m, memory: 512Mi}}` |

## Security Notes

- Change `auth.password` before production use, or use `auth.existingSecret` to supply your own Secret.
- The Redis container runs as a non-root user by default.
- The chart drops Linux capabilities and uses `RuntimeDefault` seccomp by default.
- Service account token automount is disabled on all StatefulSet pods.
- Add resource requests and limits for production workloads.

## Cleanup

```bash
helm uninstall redis -n <namespace>
```

PVCs created by StatefulSets may remain after uninstall depending on the cluster and Kubernetes version.
