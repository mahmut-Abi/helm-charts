# MySQL Helm Chart

This chart deploys MySQL in either standalone mode or a GTID-based primary-replica replication mode.

## Modes

### Standalone

Standalone mode is the default. It creates one StatefulSet, one client Service, one headless Service, one Secret (unless `auth.existingSecret` is set), and one PVC per pod.

```bash
helm install mysql ./mysql --set auth.rootPassword=my-secret-pw
```

### Cluster Mode

Cluster mode creates two StatefulSets:

- `<release>-mysql-primary`: one primary pod with `server-id=1`, binary logging, and GTID enabled
- `<release>-mysql-replica`: `cluster.replicas - 1` read replica pods

```bash
helm install mysql ./mysql \
  --set auth.rootPassword=my-secret-pw \
  --set auth.replicationPassword=repl-pw \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

With `cluster.replicas=3`, the chart creates one primary and two replicas.

The primary runs an init script that creates a replication user with `REPLICATION SLAVE` privileges. Replicas use GTID auto-positioning (`SOURCE_AUTO_POSITION=1`) to catch up from the primary. A custom entrypoint script on each replica pod:

1. Waits for the primary to be reachable via `mysqladmin ping`
2. Starts MySQL temporarily, configures replication via `CHANGE REPLICATION SOURCE TO ... START REPLICA`
3. Shuts down the bootstrap instance and restarts MySQL with `--skip-replica-start=0`

The main Service, `<release>-mysql`, selects only the primary pod and is intended for read-write traffic. The headless Service is used for stable StatefulSet DNS.

This chart does not provide automatic primary failover. If the primary fails, Kubernetes may restart the primary pod, but the chart will not promote a replica.

## Role Discovery

The pod names make the role clear in cluster mode:

```text
<release>-mysql-primary-0    primary
<release>-mysql-replica-0    read replica
<release>-mysql-replica-1    read replica
```

Confirm the role from inside a pod:

```bash
kubectl exec -n <namespace> <pod> -- \
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW REPLICA STATUS\G"
```

On a primary this returns an empty set. On a replica it shows replication state including `Source_Host`.

Check the primary's replication users:

```bash
kubectl exec -n <namespace> <release>-mysql-primary-0 -- \
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e \
  "SELECT user, host, Repl_slave_priv FROM mysql.user WHERE Repl_slave_priv='Y'"
```

## Important Values

| Value | Description | Default |
|---|---|---|
| `auth.rootPassword` | MySQL root password | `""` |
| `auth.database` | Optional initial database | `""` |
| `auth.user` | Optional application user | `""` |
| `auth.password` | Optional application password | `""` |
| `auth.existingSecret` | Use an existing Secret instead of rendering one | `""` |
| `auth.replicationUser` | Replication role for GTID replicas | `replicator` |
| `auth.replicationPassword` | Replication role password | `replicator-password` |
| `cluster.enabled` | Enable primary plus replica StatefulSets | `false` |
| `cluster.replicas` | Total pods in cluster mode (min 3) | `3` |
| `persistence.enabled` | Create PVCs for data | `true` |
| `persistence.size` | PVC size | `8Gi` |
| `resources` | Container CPU/memory requests and limits | `{requests: {cpu: 100m, memory: 256Mi}, limits: {cpu: 500m, memory: 512Mi}}` |
| `volumePermissions.enabled` | Run an initContainer to fix PVC ownership | `true` |

## Security Notes

- Set `auth.rootPassword` explicitly or use `auth.existingSecret` to supply your own Secret.
- The main MySQL container runs as a non-root user by default (UID 999).
- `volumePermissions` uses a short-lived root initContainer to set PVC ownership, then the main container runs non-root.
- Service account token automount is disabled on all StatefulSet pods.
- Capabilities are dropped, `seccompProfile` is `RuntimeDefault`, and `allowPrivilegeEscalation` is disabled.
- `readOnlyRootFilesystem` is not enabled by default to avoid unknown write paths in the MySQL image. Tune this for your deployment.

## Cleanup

```bash
helm uninstall mysql -n <namespace>
```

PVCs created by StatefulSets may remain after uninstall depending on the cluster and Kubernetes version.