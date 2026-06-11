{{/*
Expand the name of the chart.
*/}}
{{- define "langfuse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "langfuse.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "langfuse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "langfuse.labels" -}}
helm.sh/chart: {{ include "langfuse.chart" . }}
{{ include "langfuse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "langfuse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "langfuse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Web labels.
*/}}
{{- define "langfuse.webSelectorLabels" -}}
{{ include "langfuse.selectorLabels" . }}
app.kubernetes.io/component: web
{{- end -}}

{{/*
Worker labels.
*/}}
{{- define "langfuse.workerSelectorLabels" -}}
{{ include "langfuse.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end -}}

{{/*
Secret name.
*/}}
{{- define "langfuse.secretName" -}}
{{- default (printf "%s-auth" (include "langfuse.fullname" .) | trunc 63 | trimSuffix "-") .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Chart-managed auth Secret name.
*/}}
{{- define "langfuse.generatedSecretName" -}}
{{- printf "%s-auth" (include "langfuse.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Chart-managed dependency credential Secret name.
*/}}
{{- define "langfuse.credentialsSecretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- printf "%s-credentials" (include "langfuse.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "langfuse.generatedSecretName" . -}}
{{- end -}}
{{- end -}}

{{/*
Whether the chart-managed Secret should be rendered.
*/}}
{{- define "langfuse.renderGeneratedSecret" -}}
{{- if or (not .Values.auth.existingSecret) .Values.postgres.password .Values.postgres.directUrl .Values.clickhouse.password .Values.clickhouse.migrationUrl .Values.redis.connectionString .Values.s3.accessKeyId .Values.s3.secretAccessKey -}}true{{- end -}}
{{- end -}}

{{/*
DATABASE_URL: direct URL or constructed from components.
*/}}
{{- define "langfuse.databaseUrlValue" -}}
{{- if .Values.postgres.directUrl -}}
{{- .Values.postgres.directUrl -}}
{{- else -}}
{{- $url := printf "postgresql://%s:%s@%s:%d/%s" .Values.postgres.user .Values.postgres.password .Values.postgres.host (int .Values.postgres.port) .Values.postgres.database -}}
{{- if .Values.postgres.schema -}}
{{- printf "%s?schema=%s" $url .Values.postgres.schema -}}
{{- else -}}
{{- $url -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Backward-compatible DATABASE_URL helper.
*/}}
{{- define "langfuse.databaseUrl" -}}
{{- include "langfuse.databaseUrlValue" . -}}
{{- end -}}

{{/*
DATABASE_URL env value.
*/}}
{{- define "langfuse.databaseUrlEnvValue" -}}
{{- if or .Values.postgres.directUrl .Values.postgres.password }}
valueFrom:
  secretKeyRef:
    name: {{ include "langfuse.credentialsSecretName" . }}
    key: DATABASE_URL
{{- else if .Values.postgres.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.postgres.existingSecret }}
    key: {{ .Values.postgres.existingSecretKey | default "DATABASE_URL" }}
{{- else }}
value: {{ include "langfuse.databaseUrlValue" . | quote }}
{{- end }}
{{- end -}}

{{/*
ClickHouse password env value.
*/}}
{{- define "langfuse.clickhousePasswordEnvValue" -}}
{{- if .Values.clickhouse.password }}
valueFrom:
  secretKeyRef:
    name: {{ include "langfuse.credentialsSecretName" . }}
    key: CLICKHOUSE_PASSWORD
{{- else if .Values.clickhouse.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.clickhouse.existingSecret }}
    key: {{ .Values.clickhouse.existingSecretKey | default "CLICKHOUSE_PASSWORD" }}
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
ClickHouse migration URL env value.
*/}}
{{- define "langfuse.clickhouseMigrationUrlEnvValue" -}}
{{- if or .Values.clickhouse.migrationUrl .Values.clickhouse.password }}
valueFrom:
  secretKeyRef:
    name: {{ include "langfuse.credentialsSecretName" . }}
    key: CLICKHOUSE_MIGRATION_URL
{{- else if and .Values.clickhouse.existingSecret .Values.clickhouse.migrationUrlExistingSecretKey }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.clickhouse.existingSecret }}
    key: {{ .Values.clickhouse.migrationUrlExistingSecretKey }}
{{- else }}
value: {{ include "langfuse.clickhouseMigrationUrlValue" . | quote }}
{{- end }}
{{- end -}}

{{/*
Redis connection string env value.
*/}}
{{- define "langfuse.redisConnectionStringEnvValue" -}}
{{- if .Values.redis.connectionString }}
valueFrom:
  secretKeyRef:
    name: {{ include "langfuse.credentialsSecretName" . }}
    key: REDIS_CONNECTION_STRING
{{- else if .Values.redis.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.redis.existingSecret }}
    key: {{ .Values.redis.existingSecretKey | default "REDIS_CONNECTION_STRING" }}
{{- end }}
{{- end -}}

{{/*
S3 access key env value.
*/}}
{{- define "langfuse.s3AccessKeyIdEnvValue" -}}
{{- if .Values.s3.accessKeyId }}
valueFrom:
  secretKeyRef:
    name: {{ include "langfuse.credentialsSecretName" . }}
    key: LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID
{{- else if .Values.s3.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.s3.existingSecret }}
    key: {{ .Values.s3.existingSecretAccessKeyIdKey | default "LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID" }}
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
S3 secret key env value.
*/}}
{{- define "langfuse.s3SecretAccessKeyEnvValue" -}}
{{- if .Values.s3.secretAccessKey }}
valueFrom:
  secretKeyRef:
    name: {{ include "langfuse.credentialsSecretName" . }}
    key: LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY
{{- else if .Values.s3.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.s3.existingSecret }}
    key: {{ .Values.s3.existingSecretSecretAccessKeyKey | default "LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY" }}
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
Service account name.
*/}}
{{- define "langfuse.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "langfuse.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Web container image. Uses web.image if set, falls back to top-level image.
*/}}
{{- define "langfuse.webImage" -}}
{{- $repo := .Values.web.image.repository -}}
{{- $tag := .Values.web.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.tag -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Chart.AppVersion -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Worker container image. Uses worker.image if set, falls back to top-level image.
*/}}
{{- define "langfuse.workerImage" -}}
{{- $repo := .Values.worker.image.repository -}}
{{- $tag := .Values.worker.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.tag -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Chart.AppVersion -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{/*
Construct CLICKHOUSE_MIGRATION_URL (clickhouse:// protocol) from clickhouse.url.
Uses clickhouse.migrationUrl if set, otherwise derives from clickhouse.url.
*/}}
{{- define "langfuse.clickhouseMigrationUrlValue" -}}
{{- if .Values.clickhouse.migrationUrl -}}
{{- .Values.clickhouse.migrationUrl -}}
{{- else if .Values.clickhouse.url -}}
{{- $host := .Values.clickhouse.url | splitList "://" | last | splitList ":" | first -}}
{{- printf "clickhouse://%s:%s@%s:9000/%s" .Values.clickhouse.user .Values.clickhouse.password $host .Values.clickhouse.database -}}
{{- else -}}
{{- printf "clickhouse://%s:%s@%s:%d/%s" .Values.clickhouse.user .Values.clickhouse.password .Values.clickhouse.host (int .Values.clickhouse.httpPort) .Values.clickhouse.database -}}
{{- end -}}
{{- end -}}

{{/*
Backward-compatible ClickHouse migration URL helper.
*/}}
{{- define "langfuse.clickhouseMigrationUrl" -}}
{{- include "langfuse.clickhouseMigrationUrlValue" . -}}
{{- end -}}
