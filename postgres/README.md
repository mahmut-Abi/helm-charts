# PostgreSQL Helm Chart

This chart deploys PostgreSQL in either standalone mode or a simple streaming-replication cluster mode.

## Modes

### Standalone

Standalone mode is the default. It creates one StatefulSet, one client Service, one headless Service, one Secret (unless `auth.existingSecret` is set), and one PVC per pod.

```bash
helm install pg ./postgres
```

Increase `replicaCount` only if you intentionally want multiple independent PostgreSQL pods. Standalone mode does not configure replication.

### Cluster Mode

Cluster mode creates two StatefulSets:

- `<release>-postgres-primary`: one primary pod
- `<release>-postgres-replica`: `cluster.replicas - 1` read replica pods

```bash
helm install pg ./postgres \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

With `cluster.replicas=3`, the chart creates one primary and two read replicas. Replicas are bootstrapped with `pg_basebackup` and use physical streaming replication.

The main Service, `<release>-postgres`, selects only the primary pod and is intended for read-write traffic. The headless Service is used for stable StatefulSet DNS.

This chart does not provide automatic primary failover. If the primary fails, Kubernetes may restart the primary pod, but the chart will not promote a replica.

## Role Discovery

The pod names make the role clear in cluster mode:

```text
<release>-postgres-primary-0    primary
<release>-postgres-replica-0    read replica
<release>-postgres-replica-1    read replica
```

Confirm the role from inside a pod:

```bash
kubectl exec -n <namespace> <pod> -- \
  psql -U postgres -d postgres -c "select pg_is_in_recovery();"
```

Result meaning:

- `f`: primary
- `t`: replica

Check replication connections on the primary:

```bash
kubectl exec -n <namespace> <release>-postgres-primary-0 -- \
  psql -U postgres -d postgres -c \
  "select application_name, client_addr, state, sync_state from pg_stat_replication;"
```

## Important Values

| Value | Description | Default |
|---|---|---|
| `auth.postgresUser` | PostgreSQL superuser | `postgres` |
| `auth.postgresPassword` | PostgreSQL password | `postgres` |
| `auth.postgresDatabase` | Initial database | `postgres` |
| `auth.existingSecret` | Use an existing Secret instead of rendering one | `""` |
| `auth.replicationUser` | Replication role for streaming replicas | `replicator` |
| `auth.replicationPassword` | Replication role password | `replicator-password` |
| `cluster.enabled` | Enable primary plus replica StatefulSets | `false` |
| `cluster.replicas` | Total pods in cluster mode | `3` |
| `persistence.enabled` | Create PVCs for data | `true` |
| `persistence.size` | PVC size | `8Gi` |
| `resources` | Container CPU/memory requests and limits | `{requests: {cpu: 100m, memory: 256Mi}, limits: {cpu: 500m, memory: 512Mi}}` |
| `volumePermissions.enabled` | Run an initContainer to fix PVC ownership | `true` |

## Security Notes

- Change all default passwords before production use, or use `auth.existingSecret` to supply your own Secret.
- The main PostgreSQL container runs as a non-root user by default.
- `volumePermissions` uses a short-lived root initContainer to set PVC ownership, then the main container runs non-root.
- Service account token automount is disabled on all StatefulSet pods.
- Set production-grade `resources.requests` and `resources.limits` for predictable scheduling.

## Cleanup

```bash
helm uninstall pg -n <namespace>
```

PVCs created by StatefulSets may remain after uninstall depending on the cluster and Kubernetes version.
