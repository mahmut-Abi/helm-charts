# Tempo Helm Chart

This chart deploys [Grafana Tempo](https://grafana.com/docs/tempo/latest/), a distributed tracing backend. Tempo stores traces and provides a query API — it does not index traces, making it cost-efficient and operationally simple.

## Monolithic Mode

Monolithic mode is the default. All Tempo components (distributor, ingester, compactor, querier, query-frontend, metrics-generator) run in a single Deployment.

```bash
helm install tempo ./tempo
```

### With S3 Storage

```bash
helm install tempo ./tempo \
  --set storage.backend=s3 \
  --set storage.s3.bucket=tempo-traces \
  --set storage.s3.endpoint=https://s3.amazonaws.com \
  --set storage.s3.accessKey=AKI... \
  --set storage.s3.secretKey=... \
  --set storage.s3.region=us-east-1
```

### With Metrics Generator

Enable the metrics generator to produce span-metrics and service-graphs:

```bash
helm install tempo ./tempo \
  --set tempo.metricsGenerator.enabled=true \
  --set 'tempo.metricsGenerator.remoteWrite[0].url=http://prometheus:9090/api/v1/write'
```

## Endpoints

| Endpoint | Port | Protocol | Purpose |
|---|---|---|---|
| OTLP gRPC | 4317 | gRPC | Receive traces from OTel Collector / SDKs |
| OTLP HTTP | 4318 | HTTP | Receive traces via OTLP/HTTP |
| Tempo HTTP API | 3200 | HTTP | Query traces, health checks |
| Tempo Metrics | 3100 | HTTP | Prometheus metrics endpoint |

## Querying Traces

```bash
# Port-forward the Tempo HTTP API
kubectl port-forward -n <namespace> svc/<release>-tempo 3200:3200

# Search for traces
curl http://localhost:3200/api/search?q={} | jq

# Get a specific trace by ID
curl http://localhost:3200/api/traces/<trace-id> | jq
```

## Important Values

| Value | Description | Default |
|---|---|---|
| `image.repository` | Tempo Docker image | `grafana/tempo` |
| `image.tag` | Tempo version | `2.7.1` |
| `replicaCount` | Number of replicas | `1` |
| `storage.backend` | Storage backend (`local` or `s3`) | `local` |
| `storage.local.persistence.enabled` | Create a PVC for local storage | `true` |
| `storage.local.persistence.size` | PVC size | `10Gi` |
| `storage.s3.bucket` | S3 bucket name | `""` |
| `storage.s3.endpoint` | S3 endpoint URL | `""` |
| `storage.s3.accessKey` | S3 access key | `""` |
| `storage.s3.secretKey` | S3 secret key | `""` |
| `tempo.compactor.compaction.blockRetention` | Trace retention period | `48h` |
| `tempo.metricsGenerator.enabled` | Enable metrics generator | `false` |
| `service.type` | Service type | `ClusterIP` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `1Gi` |

## Cleanup

```bash
helm uninstall tempo -n <namespace> --ignore-not-found
```

Manually delete PVCs if local storage was used:

```bash
kubectl delete pvc -n <namespace> -l app.kubernetes.io/name=tempo
```