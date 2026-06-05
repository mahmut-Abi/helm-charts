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
DATABASE_URL: direct URL or constructed from components.
*/}}
{{- define "langfuse.databaseUrl" -}}
{{- if .Values.postgres.directUrl -}}
{{- .Values.postgres.directUrl -}}
{{- else -}}
{{- printf "postgresql://%s:%s@%s:%d/%s" .Values.postgres.user .Values.postgres.password .Values.postgres.host (int .Values.postgres.port) .Values.postgres.database -}}
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
{{- define "langfuse.clickhouseMigrationUrl" -}}
{{- if .Values.clickhouse.migrationUrl -}}
{{- .Values.clickhouse.migrationUrl -}}
{{- else if .Values.clickhouse.url -}}
{{- $host := .Values.clickhouse.url | splitList "://" | last | splitList ":" | first -}}
{{- if .Values.clickhouse.clusterEnabled -}}
{{- $clusterName := default "default" .Values.clickhouse.clusterName -}}
{{- printf "clickhouse://%s:%s@%s:9000/%s?x-cluster-name=%s&x-migrations-table-engine=ReplicatedMergeTree" .Values.clickhouse.user .Values.clickhouse.password $host .Values.clickhouse.database $clusterName -}}
{{- else -}}
{{- printf "clickhouse://%s:%s@%s:9000/%s" .Values.clickhouse.user .Values.clickhouse.password $host .Values.clickhouse.database -}}
{{- end -}}
{{- end -}}
{{- end -}}
