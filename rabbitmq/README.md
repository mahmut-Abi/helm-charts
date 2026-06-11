# RabbitMQ Helm Chart

This chart deploys RabbitMQ in either standalone mode or a clustered mode using the Erlang distribution mechanism.

## Quick Start

```bash
helm install rabbitmq ./rabbitmq
```

## Modes

### Standalone

Standalone mode is the default. It creates one StatefulSet, one client Service, one headless Service, one Secret (unless `auth.existingSecret` is set), and one PVC per pod.

### Cluster Mode

Cluster mode creates a single StatefulSet with `cluster.replicas` pods. Nodes form a cluster using the shared Erlang cookie and stable StatefulSet DNS names.

```bash
helm install rabbitmq ./rabbitmq \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

The Erlang cookie must be identical across all nodes. Leave `auth.erlangCookie` empty to let the chart generate and then reuse one, or supply a fixed value/existing Secret from your secret manager.

#### Cluster Formation

- Pod ordinal `0` starts as a standalone RabbitMQ node
- Pods `1+` wait for node-0's EPMD port (`4369`) to be reachable, then join the cluster via `rabbitmqctl join_cluster`
- The headless Service (`<release>-rabbitmq-headless`) has `publishNotReadyAddresses: true` so nodes can discover each other before individual readiness probes pass
- `RABBITMQ_USE_LONGNAME=true` ensures node names match the full DNS pattern
- `RABBITMQ_NODENAME` is set to `rabbit@<pod>.<headless>.<ns>.svc.cluster.local`

This chart does not provide automatic queue mirroring or HA policies. Configure those through the management UI or `rabbitmqctl` after deployment.

## Services and Ports

| Service | Port | Purpose |
|---|---|---|
| `<release>-rabbitmq` | 5672 | AMQP 0-9-1 messaging |
| `<release>-rabbitmq` | 15672 | Management HTTP API and UI |
| `<release>-rabbitmq` | 4369 | Erlang Port Mapper Daemon |
| `<release>-rabbitmq-headless` | 25672 | Inter-node Erlang distribution (cluster only) |

The management UI is available at `http://<release>-rabbitmq:15672`. Log in with `auth.defaultUser` and `auth.defaultPass`.

## Role Discovery

In cluster mode, check the cluster status from any pod:

```bash
kubectl exec -n <namespace> <release>-rabbitmq-0 -- rabbitmqctl cluster_status
```

Output includes a list of running nodes (`running_nodes`) and disc nodes. Each running node corresponds to a StatefulSet pod.

## Important Values

| Value | Description | Default |
|---|---|---|
| `auth.defaultUser` | RabbitMQ admin user | `admin` |
| `auth.defaultPass` | RabbitMQ admin password; empty generates and reuses a Secret value | `""` |
| `auth.erlangCookie` | Erlang cookie for cluster auth; empty generates and reuses a Secret value | `""` |
| `auth.existingSecret` | Use an existing Secret instead of rendering one | `""` |
| `cluster.enabled` | Enable cluster mode | `false` |
| `cluster.replicas` | Number of cluster nodes | `3` |
| `cluster.distPort` | Inter-node Erlang distribution port | `25672` |
| `service.amqpPort` | AMQP client port | `5672` |
| `service.managementPort` | Management UI/API port | `15672` |
| `service.epmdPort` | EPMD port | `4369` |
| `persistence.enabled` | Create PVCs for Mnesia data | `true` |
| `persistence.size` | PVC size | `8Gi` |
| `resources` | Container CPU/memory requests and limits | `{requests: {cpu: 100m, memory: 256Mi}, limits: {cpu: 500m, memory: 512Mi}}` |
| `volumePermissions.enabled` | Run an initContainer to fix PVC ownership | `true` |

## Security Notes

- Leave password/cookie values empty only if you want Helm to generate and then reuse the chart-managed Secret. For production GitOps, prefer `auth.existingSecret` or explicit values sourced from a secret manager.
- The main RabbitMQ container runs as a non-root user (UID 999, the `rabbitmq` user).
- `volumePermissions` uses a short-lived root initContainer (with only `CHOWN`/`FOWNER` capabilities) to set ownership on `/var/lib/rabbitmq`, then the main container runs non-root.
- Service account token automount is disabled on all StatefulSet pods.
- Capabilities are dropped, `seccompProfile` is `RuntimeDefault`, and `allowPrivilegeEscalation` is disabled.
- `RABBITMQ_DEFAULT_PASS` and `RABBITMQ_ERLANG_COOKIE` are stored in a Kubernetes Secret and never appear in plain text in the pod spec.
- Termination grace period is 60 seconds to allow RabbitMQ to flush pending writes before shutdown.

## Cleanup

```bash
helm uninstall rabbitmq -n <namespace>
```

PVCs created by StatefulSets may remain after uninstall depending on the cluster and Kubernetes version.
