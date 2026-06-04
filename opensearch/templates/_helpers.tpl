{{/*
Expand the name of the chart.
*/}}
{{- define "opensearch.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "opensearch.fullname" -}}
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
{{- define "opensearch.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "opensearch.labels" -}}
helm.sh/chart: {{ include "opensearch.chart" . }}
{{ include "opensearch.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "opensearch.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opensearch.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Secret name used by the StatefulSet.
*/}}
{{- define "opensearch.secretName" -}}
{{- default (include "opensearch.fullname" .) .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Return the number of OpenSearch pods to create.
*/}}
{{- define "opensearch.replicaCount" -}}
{{- if .Values.cluster.enabled -}}
{{- .Values.cluster.replicas -}}
{{- else -}}
{{- .Values.replicaCount -}}
{{- end -}}
{{- end -}}

{{/*
Return the pod management policy.
*/}}
{{- define "opensearch.podManagementPolicy" -}}
{{- if .Values.podManagementPolicy -}}
{{- .Values.podManagementPolicy -}}
{{- else if .Values.cluster.enabled -}}
Parallel
{{- else -}}
OrderedReady
{{- end -}}
{{- end -}}

{{/*
Headless service name.
*/}}
{{- define "opensearch.headlessServiceName" -}}
{{- printf "%s-headless" (include "opensearch.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Validate cluster-related values.
*/}}
{{- define "opensearch.validateValues" -}}
{{- if .Values.cluster.enabled -}}
{{- $replicas := int .Values.cluster.replicas -}}
{{- if lt $replicas 2 -}}
{{- fail "cluster.replicas must be at least 2 when cluster.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Calculate minimum master nodes for quorum.
*/}}
{{- define "opensearch.minimumMasterNodes" -}}
{{- if .Values.cluster.minimumMasterNodes -}}
{{- .Values.cluster.minimumMasterNodes -}}
{{- else -}}
{{- add (div (int .Values.cluster.replicas) 2) 1 -}}
{{- end -}}
{{- end -}}

{{/*
Comma-separated list of all pod FQDNs for discovery.
*/}}
{{- define "opensearch.discoveryHosts" -}}
{{- $count := int (include "opensearch.replicaCount" .) -}}
{{- range $i, $_ := until $count -}}
{{- if $i }},{{ end -}}
{{ include "opensearch.fullname" $ }}-{{ $i }}.{{ include "opensearch.headlessServiceName" $ }}.{{ $.Release.Namespace }}.svc.{{ $.Values.cluster.clusterDomain }}
{{- end -}}
{{- end -}}
