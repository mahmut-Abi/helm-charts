# AGENTS.md — Helm Charts Repository

## Quick Validation

```bash
# Lint all charts
helm lint */Chart.yaml

# Template a single chart for sanity
helm template test ./postgres

# Lint + template all charts
for d in */; do helm lint "$d" && helm template test "$d" > /dev/null; done
```

## Repository Structure

10 independent Helm charts at repo root. No umbrella chart, no subchart dependencies. Each chart owns its own templates, values, Secrets, Services, and StatefulSets/Deployments.

| Chart | Workload | Service File | Cluster Mode |
|-------|----------|-------------|--------------|
| postgres | StatefulSet | service.yaml | `cluster.enabled` |
| redis | StatefulSet | service.yaml | `cluster.enabled` |
| clickhouse | StatefulSet | service.yaml | `cluster.enabled` + Keeper |
| kafka | StatefulSet | service.yaml | KRaft (always clustered) |
| otel | Deployment | service.yaml | — |
| mongodb | StatefulSet | **svc.yaml** | — |
| mysql | StatefulSet | **svc.yaml** | — |
| rabbitmq | StatefulSet | **svc.yaml** | — |
| langfuse | Deployment ×2 | **svc.yaml** | web + worker |
| sentry | Deployment ×6 | **svc.yaml** | web, worker, cron, relay, snuba-* |

## values.yaml Conventions

### Image MUST Be at the Top

The `image:` block comes immediately after any comment header and optional `replicaCount`. **Never** place image later in the file. This is the single most important style rule.

**Template structure to follow:**

```yaml
# Optional comment header at line 1

image:
  repository: foo/bar
  tag: "1.2.3"
  pullPolicy: IfNotPresent

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

# Chart-specific config starts here...
```

**For multi-image charts** (kafka, sentry), nest sub-images under `image:`:

```yaml
image:
  kafka:
    repository: apache/kafka
    tag: "4.3.0"
    pullPolicy: IfNotPresent
  busybox:
    repository: busybox
    tag: "1.36"
    pullPolicy: IfNotPresent
```

### Service File Naming

New charts use `templates/svc.yaml` (shorter). Older charts use `templates/service.yaml`. When creating a new chart, use `svc.yaml`.

### Stateful vs Stateless

- **StatefulSet**: Stateful workloads — databases, message queues, anything with persistent identity
- **Deployment**: Stateless workloads — API servers, collectors, workers
- A chart can have both (e.g., ClickHouse: StatefulSet for server pods + StatefulSet for Keeper)

## Secret Handling

Follow the `existingSecret` pattern — every chart that generates secrets supports an `existingSecret` value. When set, the chart skips rendering `secret.yaml` and expects the Secret to exist already.

## .gitignore

```
.sisyphus/
*/my-values.yaml
```

- `.sisyphus/` — OpenCode work state (never commit)
- `*/my-values.yaml` — Local override values files (per-chart, never commit)

## Common Template Files

Every chart should have:
- `templates/_helpers.tpl` — name, labels, selector helpers
- `templates/NOTES.txt` — post-install usage instructions
- `templates/secret.yaml` — unless the chart never creates secrets
- `templates/svc.yaml` (or `service.yaml`) — client-facing Service
- `templates/statefulset.yaml` or `templates/deployment.yaml` — main workload

Stateful workloads typically add:
- `templates/pdb.yaml` — PodDisruptionBudget
- Headless service (embedded in svc.yaml or separate file)

## Consistency Rules

1. All values.yaml must use 2-space indentation
2. All comments in values.yaml should explain "why" not "what"
3. Tag strings must be quoted (`"16.3"` not `16.3`)
4. Default values must enable `helm install <name> ./<chart>` with no `--set` flags (use sensible defaults, not production defaults)
5. README.md per chart must document: quick start, important values table, and cleanup