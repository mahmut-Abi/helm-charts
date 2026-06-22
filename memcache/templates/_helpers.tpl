{{/*
Expand the name of the chart.
*/}}
{{- define "memcache.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "memcache.fullname" -}}
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
{{- define "memcache.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "memcache.labels" -}}
helm.sh/chart: {{ include "memcache.chart" . }}
{{ include "memcache.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "memcache.selectorLabels" -}}
app.kubernetes.io/name: {{ include "memcache.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Headless service name.
*/}}
{{- define "memcache.headlessServiceName" -}}
{{- printf "%s-headless" (include "memcache.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
ServiceAccount name.
*/}}
{{- define "memcache.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "memcache.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Return the pod management policy.
*/}}
{{- define "memcache.podManagementPolicy" -}}
{{- if .Values.podManagementPolicy -}}
{{- .Values.podManagementPolicy -}}
{{- else -}}
OrderedReady
{{- end -}}
{{- end -}}
