# MongoDB Helm Chart

This chart deploys MongoDB in either standalone mode or a replica-set mode.

## Modes

### Standalone

Standalone mode is the default. It creates one StatefulSet, one client Service, one headless Service, one Secret (unless `auth.existingSecret` is set), and one PVC per pod.

```bash
helm install mongodb ./mongodb --set auth.rootPassword=my-secret-pw
```

### Replica Set Mode

Replica set mode creates a single StatefulSet with `cluster.members` pods plus a Helm hook Job that initializes the replica set.

```bash
helm install mongodb ./mongodb \
  --set auth.rootPassword=my-secret-pw \
  --set cluster.enabled=true \
  --set cluster.members=3
```

An odd number of members (3, 5, or 7) is recommended for quorum-based elections.

The post-install Helm hook Job `<release>-mongodb-replica-init`:

1. Waits for pod-0 to become ready via `db.adminCommand('ping')`
2. Checks if the replica set is already initialized (`rs.status().ok`)
3. Calls `rs.initiate()` with all pod DNS names
4. Waits up to 60 seconds for a PRIMARY to be elected

The hook uses `automountServiceAccountToken: false` and the same security context as the main pods. It is deleted after a successful run.

## Role Discovery

Connect to any pod and run:

```bash
kubectl exec -n <namespace> <release>-mongodb-0 -- \
  mongosh -u admin -p <password> --authenticationDatabase admin \
  --eval "rs.status().members.map(m => ({name: m.name, state: m.stateStr}))"
```

The output maps each member hostname to its state (`PRIMARY`, `SECONDARY`, etc.).

## Important Values

| Value | Description | Default |
|---|---|---|
| `auth.rootUser` | MongoDB root user | `admin` |
| `auth.rootPassword` | MongoDB root password | `""` |
| `auth.database` | Optional initial database | `""` |
| `auth.existingSecret` | Use an existing Secret instead of rendering one | `""` |
| `cluster.enabled` | Enable replica set mode | `false` |
| `cluster.members` | Number of replica set members (1, 3, 5, or 7) | `3` |
| `cluster.replicaSetName` | Replica set name | `rs0` |
| `cluster.initJob.enabled` | Run the `rs.initiate()` hook Job | `true` |
| `persistence.enabled` | Create PVCs for data | `true` |
| `persistence.size` | PVC size | `8Gi` |
| `resources` | Container CPU/memory requests and limits | `{requests: {cpu: 100m, memory: 256Mi}, limits: {cpu: 500m, memory: 512Mi}}` |
| `volumePermissions.enabled` | Run an initContainer to fix PVC ownership | `true` |

## Security Notes

- Set `auth.rootPassword` explicitly or use `auth.existingSecret` to supply your own Secret.
- The main MongoDB container runs as a non-root user (UID 999, the `mongodb` user).
- `volumePermissions` uses a short-lived root initContainer (with only `CHOWN`/`FOWNER` capabilities) to set ownership on both `/data/db` and `/data/configdb`, then the main container runs non-root.
- Service account token automount is disabled on both the StatefulSet pods and the replica-init Job.
- Capabilities are dropped, `seccompProfile` is `RuntimeDefault`, and `allowPrivilegeEscalation` is disabled.
- `readOnlyRootFilesystem` is not enabled by default — tune this for your deployment after verifying the MongoDB image write paths.

## Cleanup

```bash
helm uninstall mongodb -n <namespace>
```

PVCs created by StatefulSets may remain after uninstall depending on the cluster and Kubernetes version.