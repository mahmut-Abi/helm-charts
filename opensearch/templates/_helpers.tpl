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
ConfigMap name used by the StatefulSet.
*/}}
{{- define "opensearch.configMapName" -}}
{{- printf "%s-config" (include "opensearch.fullname" .) | trunc 63 | trimSuffix "-" -}}
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
{{- if and (not .Values.security.disabled) (not .Values.security.useDemoCerts) -}}
{{- if not .Values.security.tls.existingSecret -}}
{{- fail "security.tls.existingSecret is required when security is enabled and security.useDemoCerts is false" -}}
{{- end -}}
{{- if not .Values.security.tls.nodesDn -}}
{{- fail "security.tls.nodesDn is required when security is enabled and security.useDemoCerts is false" -}}
{{- end -}}
{{- if not .Values.security.tls.adminDn -}}
{{- fail "security.tls.adminDn is required when security is enabled and security.useDemoCerts is false" -}}
{{- end -}}
{{- end -}}
{{- if and .Values.ingress.enabled .Values.gateway.enabled -}}
{{- fail "ingress.enabled and gateway.enabled are mutually exclusive; enable only one" -}}
{{- end -}}
{{- if and .Values.ingress.enabled (not .Values.ingress.hostname) -}}
{{- fail "ingress.hostname is required when ingress.enabled is true" -}}
{{- end -}}
{{- if .Values.gateway.enabled -}}
{{- if not .Values.gateway.gatewayName -}}
{{- fail "gateway.gatewayName is required when gateway.enabled is true" -}}
{{- end -}}
{{- if not .Values.gateway.hostname -}}
{{- fail "gateway.hostname is required when gateway.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return pod names used for cluster-manager bootstrap.
*/}}
{{- define "opensearch.initialClusterManagerNodes" -}}
{{- $nodes := .Values.cluster.initialClusterManagerNodes -}}
{{- if not $nodes -}}
{{- $nodes = list -}}
{{- $count := int (include "opensearch.replicaCount" .) -}}
{{- range $i, $_ := until $count -}}
{{- $nodes = append $nodes (printf "%s-%d" (include "opensearch.fullname" $) $i) -}}
{{- end -}}
{{- end -}}
{{- toYaml $nodes -}}
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

{{/*
YAML list of all pod FQDNs for discovery.
*/}}
{{- define "opensearch.discoveryHostsYaml" -}}
{{- $count := int (include "opensearch.replicaCount" .) -}}
{{- range $i, $_ := until $count }}
- {{ include "opensearch.fullname" $ }}-{{ $i }}.{{ include "opensearch.headlessServiceName" $ }}.{{ $.Release.Namespace }}.svc.{{ $.Values.cluster.clusterDomain | quote }}
{{- end -}}
{{- end -}}

{{/*
Return the name of the ServiceAccount used by the StatefulSet.
*/}}
{{- define "opensearch.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "opensearch.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
HTTP scheme used by OpenSearch probes and notes.
*/}}
{{- define "opensearch.httpScheme" -}}
{{- if .Values.security.disabled -}}http{{- else -}}https{{- end -}}
{{- end -}}

{{/*
Shell command used by startup/liveness probes.
*/}}
{{- define "opensearch.probeCommand" -}}
{{- $scheme := include "opensearch.httpScheme" . -}}
{{- if .Values.security.disabled -}}
curl -fsS --max-time 5 {{ $scheme }}://127.0.0.1:{{ .Values.service.httpPort }}/ >/dev/null
{{- else -}}
curl -k -fsS --max-time 5 -u "${OPENSEARCH_USERNAME}:${OPENSEARCH_INITIAL_ADMIN_PASSWORD}" {{ $scheme }}://127.0.0.1:{{ .Values.service.httpPort }}/ >/dev/null
{{- end -}}
{{- end -}}

{{/*
Shell command used by readiness probe.
*/}}
{{- define "opensearch.readinessCommand" -}}
{{- $scheme := include "opensearch.httpScheme" . -}}
{{- if .Values.security.disabled -}}
curl -fsS --max-time 5 "{{ $scheme }}://127.0.0.1:{{ .Values.service.httpPort }}/_cluster/health?local=true" >/dev/null
{{- else -}}
curl -k -fsS --max-time 5 -u "${OPENSEARCH_USERNAME}:${OPENSEARCH_INITIAL_ADMIN_PASSWORD}" "{{ $scheme }}://127.0.0.1:{{ .Values.service.httpPort }}/_cluster/health?local=true" >/dev/null
{{- end -}}
{{- end -}}
