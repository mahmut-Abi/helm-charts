# Langfuse Helm Chart

This chart deploys [Langfuse](https://langfuse.com), an open-source LLM observability platform. It connects to existing PostgreSQL, ClickHouse, and Redis instances — it does not deploy its own databases.

## Components

- **Web**: Next.js frontend and API server (Deployment)
- **Worker**: Background job processor (Deployment) — runs Prisma migrations on startup

## Quick Start

```bash
helm install langfuse ./langfuse \
  --set auth.salt=$(openssl rand -hex 16) \
  --set auth.encryptionKey=$(openssl rand -hex 32) \
  --set auth.nextauthSecret=$(openssl rand -hex 32) \
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

Set them via `--set` or a values file. Never commit plaintext secrets.

## Important Values

| Value | Description | Default |
|---|---|---|
| `auth.salt` | Password hashing salt | `""` |
| `auth.encryptionKey` | 256-bit data encryption key (64 hex chars) | `""` |
| `auth.nextauthSecret` | NextAuth.js signing secret | `""` |
| `auth.nextauthUrl` | Public URL | `http://localhost:3000` |
| `postgres.host` | PostgreSQL hostname | `""` |
| `postgres.password` | PostgreSQL password | `""` |
| `clickhouse.url` | ClickHouse HTTP URL | `""` |
| `redis.connectionString` | Redis connection URI | `""` |
| `s3.enabled` | Enable S3 event storage | `false` |
| `web.replicas` | Web pods | `1` |
| `worker.replicas` | Worker pods | `1` |

## Health

The web server exposes `/api/public/health` for liveness and readiness probes. The worker uses a process check (`pgrep`).

## Cleanup

```bash
helm uninstall langfuse -n <namespace>
```