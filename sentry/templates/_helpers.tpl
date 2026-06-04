{{/*
Expand the name of the chart.
*/}}
{{- define "sentry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "sentry.fullname" -}}
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
{{- define "sentry.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "sentry.labels" -}}
helm.sh/chart: {{ include "sentry.chart" . }}
{{ include "sentry.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "sentry.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Web selector labels.
*/}}
{{- define "sentry.webSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: web
{{- end -}}

{{/*
Worker selector labels.
*/}}
{{- define "sentry.workerSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end -}}

{{/*
Cron selector labels.
*/}}
{{- define "sentry.cronSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: cron
{{- end -}}

{{/*
Relay selector labels.
*/}}
{{- define "sentry.relaySelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: relay
{{- end -}}

{{/*
Snuba API selector labels.
*/}}
{{- define "sentry.snubaApiSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: snuba-api
{{- end -}}

{{/*
Snuba consumer selector labels.
*/}}
{{- define "sentry.snubaConsumerSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: snuba-consumer
{{- end -}}

{{/*
Secret name.
*/}}
{{- define "sentry.secretName" -}}
{{- default (printf "%s-auth" (include "sentry.fullname" .) | trunc 63 | trimSuffix "-") .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Web container image. Uses web.image if set, falls back to top-level image.
*/}}
{{- define "sentry.webImage" -}}
{{- $repo := .Values.web.image.repository -}}
{{- $tag := .Values.web.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.sentry.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.sentry.tag -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Worker container image. Uses worker.image if set, falls back to top-level image.
*/}}
{{- define "sentry.workerImage" -}}
{{- $repo := .Values.worker.image.repository -}}
{{- $tag := .Values.worker.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.sentry.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.sentry.tag -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Relay container image. Uses relay.image if set, falls back to image.relay.
*/}}
{{- define "sentry.relayImage" -}}
{{- $repo := .Values.relay.image.repository -}}
{{- $tag := .Values.relay.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.relay.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.relay.tag -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Snuba container image. Uses snuba.image if set, falls back to image.snuba.
*/}}
{{- define "sentry.snubaImage" -}}
{{- $repo := .Values.snuba.image.repository -}}
{{- $tag := .Values.snuba.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.snuba.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.snuba.tag -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
PostgreSQL connection string.
*/}}
{{- define "sentry.databaseUrl" -}}
{{- printf "postgresql://%s:%s@%s:%d/%s" .Values.postgres.user .Values.postgres.password .Values.postgres.host (int .Values.postgres.port) .Values.postgres.database -}}
{{- end -}}