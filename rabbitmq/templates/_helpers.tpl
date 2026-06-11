{{/*
Expand the name of the chart.
*/}}
{{- define "rabbitmq.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "rabbitmq.fullname" -}}
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
{{- define "rabbitmq.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "rabbitmq.labels" -}}
helm.sh/chart: {{ include "rabbitmq.chart" . }}
{{ include "rabbitmq.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "rabbitmq.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rabbitmq.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Secret name.
*/}}
{{- define "rabbitmq.secretName" -}}
{{- default (printf "%s-auth" (include "rabbitmq.fullname" .) | trunc 63 | trimSuffix "-") .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Headless service name.
*/}}
{{- define "rabbitmq.headlessServiceName" -}}
{{- printf "%s-headless" (include "rabbitmq.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Replica count.
*/}}
{{- define "rabbitmq.replicaCount" -}}
{{- if .Values.cluster.enabled -}}
{{- .Values.cluster.replicas -}}
{{- else -}}
{{- .Values.replicaCount -}}
{{- end -}}
{{- end -}}

{{/*
Erlang cookie: user-provided or auto-generated.
*/}}
{{- define "rabbitmq.erlangCookie" -}}
{{- if .Values.auth.erlangCookie -}}
{{- .Values.auth.erlangCookie -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{/*
Pod management policy: Parallel for cluster, OrderedReady for standalone.
*/}}
{{- define "rabbitmq.podManagementPolicy" -}}
{{- if .Values.cluster.enabled -}}
Parallel
{{- else -}}
OrderedReady
{{- end -}}
{{- end -}}

{{/*
ServiceAccount name.
*/}}
{{- define "rabbitmq.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "rabbitmq.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}