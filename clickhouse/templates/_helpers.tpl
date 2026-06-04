{{/*
Expand the name of the chart.
*/}}
{{- define "clickhouse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "clickhouse.fullname" -}}
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
{{- define "clickhouse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "clickhouse.labels" -}}
helm.sh/chart: {{ include "clickhouse.chart" . }}
{{ include "clickhouse.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "clickhouse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clickhouse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Secret name used by the StatefulSet.
*/}}
{{- define "clickhouse.secretName" -}}
{{- default (include "clickhouse.fullname" .) .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Return the number of ClickHouse pods to create.
*/}}
{{- define "clickhouse.replicaCount" -}}
{{- if .Values.cluster.enabled -}}
{{- mul (int .Values.cluster.shards) (int .Values.cluster.replicasPerShard) -}}
{{- else -}}
{{- .Values.replicaCount -}}
{{- end -}}
{{- end -}}

{{/*
Return the pod management policy.
*/}}
{{- define "clickhouse.podManagementPolicy" -}}
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
{{- define "clickhouse.validateValues" -}}
{{- if .Values.cluster.enabled -}}
{{- $shards := int .Values.cluster.shards -}}
{{- $replicasPerShard := int .Values.cluster.replicasPerShard -}}
{{- $keeperReplicas := int .Values.keeper.replicas -}}
{{- if lt $shards 1 -}}
{{- fail "cluster.shards must be at least 1 when cluster.enabled is true" -}}
{{- end -}}
{{- if lt $replicasPerShard 1 -}}
{{- fail "cluster.replicasPerShard must be at least 1 when cluster.enabled is true" -}}
{{- end -}}
{{- if and .Values.keeper.enabled (lt $keeperReplicas 1) -}}
{{- fail "keeper.replicas must be at least 1 when keeper.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Headless service name.
*/}}
{{- define "clickhouse.headlessServiceName" -}}
{{- printf "%s-headless" (include "clickhouse.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standalone Keeper StatefulSet name.
*/}}
{{- define "clickhouse.keeperFullname" -}}
{{- printf "%s-keeper" (include "clickhouse.fullname" . | trunc 56 | trimSuffix "-") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standalone Keeper headless service name.
*/}}
{{- define "clickhouse.keeperHeadlessServiceName" -}}
{{- printf "%s-headless" (include "clickhouse.keeperFullname" . | trunc 54 | trimSuffix "-") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels for standalone Keeper pods.
*/}}
{{- define "clickhouse.keeperSelectorLabels" -}}
app.kubernetes.io/name: {{ include "clickhouse.name" . }}-keeper
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Labels for standalone Keeper resources.
*/}}
{{- define "clickhouse.keeperLabels" -}}
helm.sh/chart: {{ include "clickhouse.chart" . }}
{{ include "clickhouse.keeperSelectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
