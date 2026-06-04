# OpenTelemetry Collector Helm Chart

This chart deploys the OpenTelemetry Collector to receive, process, and export
telemetry data (traces, metrics, and logs).

## Modes

### Standalone

Standalone mode is the default. It creates one Deployment, one Service exposing
OTLP and metrics ports, one ConfigMap for the collector configuration, and one
PodDisruptionBudget.

```bash
helm install otel ./otel
```

### Export to an OTLP Backend

Set the OTLP exporter endpoint to send data to a backend like Jaeger, Tempo, or
another collector:

```bash
helm install otel ./otel \
  --set config.exporters.otlp.endpoint=tempo.default.svc.cluster.local:4317
```

### Custom Configuration

Override the entire config block for full control over receivers, processors,
exporters, and pipelines:

```bash
helm install otel ./otel -f my-values.yaml
```

### Scaling

Increase `replicaCount` when the collector needs to handle more traffic:

```bash
helm install otel ./otel --set replicaCount=3
```

## Important Values

| Value | Description | Default |
|---|---|---|
| `config.receivers.otlp.protocols.grpc.endpoint` | OTLP gRPC listen address | `0.0.0.0:4317` |
| `config.receivers.otlp.protocols.http.endpoint` | OTLP HTTP listen address | `0.0.0.0:4318` |
| `config.exporters.otlp.endpoint` | OTLP export backend endpoint | `""` |
| `config.exporters.prometheus.endpoint` | Prometheus metrics export address | `0.0.0.0:8889` |
| `service.type` | Service type | `ClusterIP` |
| `service.otlpGrpcPort` | OTLP gRPC service port | `4317` |
| `service.otlpHttpPort` | OTLP HTTP service port | `4318` |
| `service.metricsPort` | Own metrics scrape port | `8888` |
| `service.prometheusExportPort` | Prometheus exporter port | `8889` |
| `service.healthCheckPort` | Health check port | `13133` |
| `replicaCount` | Number of collector replicas | `1` |
| `resources` | Container CPU/memory requests and limits | `{requests: {cpu: 100m, memory: 256Mi}, limits: {cpu: 500m, memory: 512Mi}}` |

## Endpoints

| Endpoint | Default Port | Protocol |
|----------|-------------|----------|
| OTLP gRPC | 4317 | gRPC |
| OTLP HTTP | 4318 | HTTP |
| Own metrics | 8888 | Prometheus |
| Prometheus exporter | 8889 | Prometheus |
| Health check | 13133 | HTTP |

## Validation

```bash
helm lint otel
helm template otel ./otel
```