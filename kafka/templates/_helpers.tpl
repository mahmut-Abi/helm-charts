{{/*
Expand the name of the chart.
*/}}
{{- define "kafka.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kafka.fullname" -}}
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
{{- define "kafka.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "kafka.labels" -}}
helm.sh/chart: {{ include "kafka.chart" . }}
{{ include "kafka.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "kafka.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kafka.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Headless service name for internal broker discovery.
*/}}
{{- define "kafka.headlessServiceName" -}}
{{- printf "%s-headless" (include "kafka.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Secret name.
*/}}
{{- define "kafka.secretName" -}}
{{- default (printf "%s-auth" (include "kafka.fullname" .) | trunc 63 | trimSuffix "-") .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Controller quorum voters: "nodeId@host:port" for each replica.
*/}}
{{- define "kafka.quorumVoters" -}}
{{- $fullname := include "kafka.fullname" . -}}
{{- $headless := include "kafka.headlessServiceName" . -}}
{{- $port := int .Values.kraft.controllerPort -}}
{{- $replicas := int .Values.replicas -}}
{{- $namespace := .Release.Namespace -}}
{{- range $i := until $replicas -}}
{{- if ne $i 0 }},{{ end -}}
{{- printf "%d@%s-%d.%s.%s.svc.cluster.local:%d" $i $fullname $i $headless $namespace $port -}}
{{- end -}}
{{- end -}}

{{/*
Advertised listeners: PLAINTEXT://pod-name.headless.namespace.svc.cluster.local:port
*/}}
{{- define "kafka.plaintextListeners" -}}
{{- $fullname := include "kafka.fullname" . -}}
{{- $headless := include "kafka.headlessServiceName" . -}}
{{- $port := .Values.service.internalPort -}}
{{- $namespace := .Release.Namespace -}}
{{- printf "PLAINTEXT://%s-${KAFKA_NODE_ID}.%s.%s.svc.cluster.local:%d" $fullname $headless $namespace (int $port) -}}
{{- end -}}

{{/*
Controller listener for KRaft.
*/}}
{{- define "kafka.controllerListener" -}}
{{- $fullname := include "kafka.fullname" . -}}
{{- $headless := include "kafka.headlessServiceName" . -}}
{{- $port := int .Values.kraft.controllerPort -}}
{{- $namespace := .Release.Namespace -}}
{{- printf "CONTROLLER://%s-${KAFKA_NODE_ID}.%s.%s.svc.cluster.local:%d" $fullname $headless $namespace (int $port) -}}
{{- end -}}

{{/*
Validate required values.
*/}}
{{- define "kafka.validateValues" -}}
{{- if lt (int .Values.replicas) 1 -}}
{{- fail "replicas must be >= 1" -}}
{{- end -}}
{{- end -}}
