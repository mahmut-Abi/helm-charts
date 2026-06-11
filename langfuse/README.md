# Langfuse Helm Chart

This chart deploys [Langfuse](https://langfuse.com), an open-source LLM observability platform. It connects to existing PostgreSQL, ClickHouse, and Redis instances — it does not deploy its own databases.

## Components

- **Web**: Next.js frontend and API server (Deployment)
- **Worker**: Background job processor (Deployment) — uses the `langfuse-worker` image and listens on port 3030
- **ClickHouse Migration Job**: Revisioned Kubernetes Job that runs ClickHouse migrations before readiness-dependent components settle

## Quick Start

```bash
helm install langfuse ./langfuse \
  --set auth.nextauthUrl=https://langfuse.example.com \
  --set postgres.host=postgres \
  --set postgres.password=my-db-password \
  --set clickhouse.url=http://clickhouse:8123 \
  --set clickhouse.password=my-ch-password \
  --set redis.connectionString=redis://:password@redis:6379/0
```

## External Dependencies

This chart expects PostgreSQL, ClickHouse, and Redis to be running externally. Use any of these to provide them:

| Dependency | Chart | Connection via |
|---|---|---|
| PostgreSQL | `./postgres` | `postgres.host` / `postgres.password` |
| ClickHouse | `./clickhouse` | `clickhouse.url` / `clickhouse.password` |
| Redis | `./redis` | `redis.connectionString` |

## Secrets

Generate strong random values with:

```bash
openssl rand -hex 32   # ENCRYPTION_KEY (64 chars)
openssl rand -hex 32   # NEXTAUTH_SECRET
openssl rand -hex 8    # SALT (16 chars)
```

Set them via `--set`, a values file, or `auth.existingSecret`. If omitted, the chart generates `SALT`, `ENCRYPTION_KEY`, and `NEXTAUTH_SECRET` on first install and reuses the chart-managed Secret on upgrade. Never commit plaintext secrets.

## Important Values

| Value | Description | Default |
|---|---|---|
| `auth.salt` | Password hashing salt; empty generates and reuses a Secret value | `""` |
| `auth.encryptionKey` | Data encryption key; empty generates and reuses a Secret value | `""` |
| `auth.nextauthSecret` | NextAuth.js signing secret; empty generates and reuses a Secret value | `""` |
| `auth.existingSecret` | Use an existing Secret for Langfuse auth keys | `""` |
| `auth.nextauthUrl` | Public URL | `http://localhost:3000` |
| `postgres.host` | PostgreSQL hostname | `""` |
| `postgres.schema` | PostgreSQL schema used when constructing `DATABASE_URL` | `public` |
| `postgres.password` | PostgreSQL password | `""` |
| `clickhouse.url` | ClickHouse HTTP URL | `""` |
| `clickhouse.httpPort` | ClickHouse HTTP port used by init and migration jobs | `8123` |
| `clickhouse.tlsEnabled` | Use HTTPS for ClickHouse init and migration checks | `false` |
| `clickhouseMigrationJob.enabled` | Run revisioned ClickHouse migration Job | `true` |
| `redis.connectionString` | Redis connection URI | `""` |
| `s3.enabled` | Enable S3 event storage | `false` |
| `web.replicas` | Web pods | `1` |
| `worker.replicas` | Worker pods | `1` |
| `serviceAccount.create` | Create a dedicated ServiceAccount | `false` |
| `networkPolicy.enabled` | Render a NetworkPolicy | `false` |

## Health

The web server exposes `/api/public/health` for liveness and readiness probes. The worker uses a process check (`pgrep`).

## Cleanup

```bash
helm uninstall langfuse -n <namespace>
```
