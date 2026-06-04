# OpenSearch Helm Chart

This chart deploys OpenSearch in standalone mode or cluster mode.

## Modes

### Standalone

Standalone mode is the default. It creates one OpenSearch StatefulSet, one client Service, one headless Service, one Secret (unless `auth.existingSecret` is set), and one PVC.

```bash
helm install os ./opensearch
```

### Cluster Mode

Cluster mode deploys multiple OpenSearch nodes that automatically discover each other via the headless Service. An odd number of nodes (3, 5, ...) is recommended for split-brain protection.

```bash
helm install os ./opensearch \
  --set cluster.enabled=true \
  --set cluster.replicas=3
```

## Security

The OpenSearch security plugin is enabled by default. The chart sets `OPENSEARCH_INITIAL_ADMIN_PASSWORD` for the `admin` user.

### Disable Security (Development Only)

```bash
helm install os ./opensearch --set security.disabled=true
```

### Demo TLS Certificates

By default, the chart relies on the demo TLS certificates bundled with the OpenSearch image (`security.useDemoCerts: true`). Set to `false` to supply your own certificates.

### Existing Secret

Use a pre-created Secret instead of having the chart generate one:

```bash
kubectl create secret generic os-secret \
  --from-literal=OPENSEARCH_INITIAL_ADMIN_PASSWORD=my-strong-password

helm install os ./opensearch --set auth.existingSecret=os-secret
```

## Cluster Verification

Check cluster health:

```bash
kubectl exec -n <namespace> <release>-opensearch-0 -- \
  curl -k -u admin:<password> \
  https://localhost:9200/_cluster/health?pretty
```

List all nodes:

```bash
kubectl exec -n <namespace> <release>-opensearch-0 -- \
  curl -k -u admin:<password> \
  https://localhost:9200/_cat/nodes?v
```

## Important Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | OpenSearch image repository | `opensearchproject/opensearch` |
| `image.tag` | OpenSearch image tag | `2.19.0` |
| `auth.adminPassword` | Initial admin password | `admin` |
| `auth.existingSecret` | Use pre-created Secret | `""` |
| `cluster.enabled` | Enable cluster mode | `false` |
| `cluster.replicas` | Number of cluster nodes | `3` |
| `security.disabled` | Disable security plugin | `false` |
| `security.useDemoCerts` | Use bundled demo TLS certs | `true` |
| `persistence.enabled` | Enable PVC | `true` |
| `persistence.size` | PVC size | `30Gi` |
| `resources.requests.cpu` | CPU request | `1` |
| `resources.requests.memory` | Memory request | `2Gi` |

## Cleanup

```bash
helm uninstall os
```