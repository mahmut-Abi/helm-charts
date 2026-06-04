{{/*
Expand the name of the chart.
*/}}
{{- define "redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "redis.fullname" -}}
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
{{- define "redis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "redis.labels" -}}
helm.sh/chart: {{ include "redis.chart" . }}
{{ include "redis.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Secret name.
*/}}
{{- define "redis.secretName" -}}
{{- default (printf "%s-auth" (include "redis.fullname" .) | trunc 63 | trimSuffix "-") .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Return the number of Redis pods to create.
*/}}
{{- define "redis.replicaCount" -}}
{{- if .Values.cluster.enabled -}}
{{- mul (int .Values.cluster.masters) (add (int .Values.cluster.replicasPerMaster) 1) -}}
{{- else -}}
{{- int .Values.replicaCount -}}
{{- end -}}
{{- end -}}

{{/*
Return the pod management policy.
*/}}
{{- define "redis.podManagementPolicy" -}}
{{- if .Values.podManagementPolicy -}}
{{- .Values.podManagementPolicy -}}
{{- else if .Values.cluster.enabled -}}
Parallel
{{- else -}}
OrderedReady
{{- end -}}
{{- end -}}

{{/*
Validate cluster-related values.
*/}}
{{- define "redis.validateValues" -}}
{{- if .Values.cluster.enabled -}}
{{- if lt (int .Values.cluster.masters) 3 -}}
{{- fail "cluster.masters must be at least 3 when cluster.enabled is true" -}}
{{- end -}}
{{- if lt (int .Values.cluster.replicasPerMaster) 0 -}}
{{- fail "cluster.replicasPerMaster cannot be negative" -}}
{{- end -}}
{{- if and .Values.auth.enabled (not .Values.auth.password) -}}
{{- fail "auth.password is required when auth.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Headless service name.
*/}}
{{- define "redis.headlessServiceName" -}}
{{- printf "%s-headless" (include "redis.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
