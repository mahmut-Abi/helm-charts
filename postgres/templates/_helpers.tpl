{{/*
Expand the name of the chart.
*/}}
{{- define "postgres.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "postgres.fullname" -}}
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
{{- define "postgres.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "postgres.labels" -}}
helm.sh/chart: {{ include "postgres.chart" . }}
{{ include "postgres.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "postgres.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgres.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Secret name.
*/}}
{{- define "postgres.secretName" -}}
{{- default (printf "%s-auth" (include "postgres.fullname" .) | trunc 63 | trimSuffix "-") .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Create the name of the service account to use.
*/}}
{{- define "postgres.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "postgres.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Return the number of PostgreSQL pods to create.
*/}}
{{- define "postgres.replicaCount" -}}
{{- if .Values.cluster.enabled -}}
{{- int .Values.cluster.replicas -}}
{{- else -}}
{{- int .Values.replicaCount -}}
{{- end -}}
{{- end -}}

{{/*
Return the number of PostgreSQL replica pods to create in cluster mode.
*/}}
{{- define "postgres.readReplicaCount" -}}
{{- sub (int .Values.cluster.replicas) 1 -}}
{{- end -}}

{{/*
Read-only service name.
*/}}
{{- define "postgres.readOnlyServiceName" -}}
{{- printf "%s-read" (include "postgres.fullname" . | trunc 58 | trimSuffix "-") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Primary StatefulSet name.
*/}}
{{- define "postgres.primaryFullname" -}}
{{- printf "%s-primary" (include "postgres.fullname" . | trunc 55 | trimSuffix "-") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Replica StatefulSet name.
*/}}
{{- define "postgres.replicaFullname" -}}
{{- printf "%s-replica" (include "postgres.fullname" . | trunc 55 | trimSuffix "-") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Primary labels.
*/}}
{{- define "postgres.primarySelectorLabels" -}}
{{ include "postgres.selectorLabels" . }}
app.kubernetes.io/component: primary
{{- end -}}

{{/*
Replica labels.
*/}}
{{- define "postgres.replicaSelectorLabels" -}}
{{ include "postgres.selectorLabels" . }}
app.kubernetes.io/component: replica
{{- end -}}

{{/*
Primary pod name.
*/}}
{{- define "postgres.primaryPodName" -}}
{{- if .Values.cluster.enabled -}}
{{- printf "%s-0" (include "postgres.primaryFullname" .) -}}
{{- else -}}
{{- printf "%s-0" (include "postgres.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Validate cluster-related values.
*/}}
{{- define "postgres.validateValues" -}}
{{- if .Values.cluster.enabled -}}
{{- if lt (int .Values.cluster.replicas) 2 -}}
{{- fail "cluster.replicas must be at least 2 when cluster.enabled is true" -}}
{{- end -}}
{{- if not .Values.auth.replicationUser -}}
{{- fail "auth.replicationUser is required when cluster.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- if and .Values.pdb.enabled .Values.cluster.enabled .Values.pdb.minAvailable .Values.pdb.maxUnavailable -}}
{{- fail "Set only one of pdb.minAvailable or pdb.maxUnavailable" -}}
{{- end -}}
{{- end -}}

{{/*
Headless service name.
*/}}
{{- define "postgres.headlessServiceName" -}}
{{- printf "%s-headless" (include "postgres.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Render optional pod scheduling settings shared by PostgreSQL StatefulSets.
*/}}
{{- define "postgres.podScheduling" -}}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.affinity }}
affinity:
  {{- toYaml .Values.affinity | nindent 2 }}
{{- else }}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              {{- include "postgres.selectorLabels" . | nindent 14 }}
          topologyKey: kubernetes.io/hostname
{{- end }}
{{- with .Values.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
