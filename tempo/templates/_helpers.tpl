{{/*
Expand the name of the chart.
*/}}
{{- define "tempo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "tempo.fullname" -}}
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
{{- define "tempo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "tempo.labels" -}}
helm.sh/chart: {{ include "tempo.chart" . }}
{{ include "tempo.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "tempo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tempo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use.
*/}}
{{- define "tempo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "tempo.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Secret name for S3 credentials.
*/}}
{{- define "tempo.s3SecretName" -}}
{{- default (printf "%s-s3" (include "tempo.fullname" .) | trunc 63 | trimSuffix "-") .Values.storage.s3.existingSecret -}}
{{- end -}}

{{/*
Validate values that can render but fail at runtime.
*/}}
{{- define "tempo.validateValues" -}}
{{- if eq .Values.storage.backend "s3" -}}
{{- if not .Values.storage.s3.bucket -}}
{{- fail "storage.s3.bucket is required when storage.backend=s3" -}}
{{- end -}}
{{- if ne (empty .Values.storage.s3.accessKey) (empty .Values.storage.s3.secretKey) -}}
{{- fail "storage.s3.accessKey and storage.s3.secretKey must be set together, or use storage.s3.existingSecret" -}}
{{- end -}}
{{- end -}}
{{- if and (gt (int .Values.replicaCount) 1) (eq .Values.storage.backend "local") -}}
{{- fail "replicaCount > 1 with storage.backend=local is unsafe because the monolithic chart mounts shared local PVCs. Use storage.backend=s3 or keep replicaCount=1." -}}
{{- end -}}
{{- end -}}
