{{/*
Expand the name of the chart.
*/}}
{{- define "mysql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mysql.fullname" -}}
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
{{- define "mysql.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "mysql.labels" -}}
helm.sh/chart: {{ include "mysql.chart" . }}
{{ include "mysql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "mysql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mysql.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Secret name.
*/}}
{{- define "mysql.secretName" -}}
{{- default (printf "%s-auth" (include "mysql.fullname" .) | trunc 63 | trimSuffix "-") .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Primary StatefulSet name.
*/}}
{{- define "mysql.primaryFullname" -}}
{{- printf "%s-primary" (include "mysql.fullname" . | trunc 55 | trimSuffix "-") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Replica StatefulSet name.
*/}}
{{- define "mysql.replicaFullname" -}}
{{- printf "%s-replica" (include "mysql.fullname" . | trunc 55 | trimSuffix "-") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Primary labels.
*/}}
{{- define "mysql.primarySelectorLabels" -}}
{{ include "mysql.selectorLabels" . }}
app.kubernetes.io/component: primary
{{- end -}}

{{/*
Replica labels.
*/}}
{{- define "mysql.replicaSelectorLabels" -}}
{{ include "mysql.selectorLabels" . }}
app.kubernetes.io/component: replica
{{- end -}}

{{/*
Headless service name.
*/}}
{{- define "mysql.headlessServiceName" -}}
{{- printf "%s-headless" (include "mysql.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Replica count for standalone mode.
*/}}
{{- define "mysql.replicaCount" -}}
{{- .Values.replicaCount -}}
{{- end -}}

{{/*
Read replica count (cluster.replicas - 1).
*/}}
{{- define "mysql.readReplicaCount" -}}
{{- int .Values.cluster.replicas | sub 1 -}}
{{- end -}}

{{/*
Validate cluster-related values.
*/}}
{{- define "mysql.validateValues" -}}
{{- if .Values.cluster.enabled -}}
{{- if lt (int .Values.cluster.replicas) 3 -}}
{{- fail "cluster.replicas must be at least 3 when cluster.enabled is true" -}}
{{- end -}}
{{- if not .Values.auth.replicationUser -}}
{{- fail "auth.replicationUser is required when cluster.enabled is true" -}}
{{- end -}}
{{- if not .Values.auth.replicationPassword -}}
{{- fail "auth.replicationPassword is required when cluster.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}