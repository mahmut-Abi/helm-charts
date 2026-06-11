{{/*
Validate values that would otherwise fail late at runtime.
*/}}
{{- define "sentry.validateValues" -}}
{{- if and .Values.ingress.enabled .Values.gateway.enabled -}}
{{- fail "ingress.enabled and gateway.enabled are mutually exclusive" -}}
{{- end -}}
{{- if and .Values.taskbroker.enabled (ne (int .Values.taskbroker.replicas) 1) -}}
{{- fail "taskbroker.replicas must be 1 because taskbroker uses a local SQLite state store" -}}
{{- end -}}
{{- if and (eq .Values.filestore.backend "s3") (not .Values.filestore.s3.bucketName) -}}
{{- fail "filestore.s3.bucketName is required when filestore.backend=s3" -}}
{{- end -}}
{{- if and (eq .Values.filestore.backend "s3") (not .Values.filestore.s3.existingSecret) (ne (not .Values.filestore.s3.accessKey) (not .Values.filestore.s3.secretKey)) -}}
{{- fail "filestore.s3.accessKey and filestore.s3.secretKey must be set together, or use filestore.s3.existingSecret" -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "sentry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "sentry.fullname" -}}
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
{{- define "sentry.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "sentry.labels" -}}
helm.sh/chart: {{ include "sentry.chart" . }}
{{ include "sentry.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "sentry.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Web selector labels.
*/}}
{{- define "sentry.webSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: web
{{- end -}}

{{/*
Worker selector labels.
*/}}
{{- define "sentry.workerSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end -}}

{{/*
Cron selector labels.
*/}}
{{- define "sentry.cronSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: cron
{{- end -}}

{{/*
Relay selector labels.
*/}}
{{- define "sentry.relaySelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: relay
{{- end -}}

{{/*
Snuba API selector labels.
*/}}
{{- define "sentry.snubaApiSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: snuba-api
{{- end -}}

{{/*
Snuba consumer selector labels.
*/}}
{{- define "sentry.snubaConsumerSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: snuba-consumer
{{- end -}}

{{/*
Ingest consumer selector labels.
*/}}
{{- define "sentry.ingestConsumerSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: ingest-consumer
{{- end -}}

{{/*
Taskbroker selector labels.
*/}}
{{- define "sentry.taskbrokerSelectorLabels" -}}
{{ include "sentry.selectorLabels" . }}
app.kubernetes.io/component: taskbroker
{{- end -}}

{{/*
Name of the chart-managed Secret. This can exist even when auth.existingSecret
is used, because inline dependency credentials are stored here.
*/}}
{{- define "sentry.generatedSecretName" -}}
{{- printf "%s-auth" (include "sentry.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name of the chart-managed Secret for inline dependency credentials. When the
Sentry auth secret is external, keep dependency credentials in a separate Secret
so the chart never overwrites the external auth Secret.
*/}}
{{- define "sentry.credentialsSecretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- printf "%s-credentials" (include "sentry.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "sentry.generatedSecretName" . -}}
{{- end -}}
{{- end -}}

{{/*
Secret name.
*/}}
{{- define "sentry.secretName" -}}
{{- default (include "sentry.generatedSecretName" .) .Values.auth.existingSecret -}}
{{- end -}}

{{/*
Whether the chart-managed Secret should be rendered.
*/}}
{{- define "sentry.renderGeneratedSecret" -}}
{{- if or (not .Values.auth.existingSecret) .Values.postgres.password .Values.redis.password .Values.clickhouse.password .Values.user.password .Values.filestore.s3.accessKey .Values.filestore.s3.secretKey -}}true{{- end -}}
{{- end -}}

{{/*
Init container that creates Kafka topics needed by Sentry, Snuba, and taskbroker.
*/}}
{{- define "sentry.kafkaTopicInitContainer" -}}
- name: init-kafka-topics
  image: "{{ .Values.image.kafka.repository }}:{{ .Values.image.kafka.tag }}"
  imagePullPolicy: {{ .Values.image.kafka.pullPolicy }}
  command:
    - /bin/bash
    - -c
    - |
      set -e
      {{- $bootstrap := .Values.kafka.bootstrapServers }}
      {{- $requiredTopics := list "ingest-events" "events" "group-attributes" "outcomes" .Values.taskbroker.kafkaTopic .Values.taskbroker.kafkaLongTopic .Values.taskbroker.kafkaDeadletterTopic }}
      {{- $userTopics := .Values.kafka.topics | default (list) }}
      {{- range concat $requiredTopics $userTopics | uniq }}
      echo "Ensuring Kafka topic: {{ . }}"
      /opt/kafka/bin/kafka-topics.sh --bootstrap-server {{ $bootstrap }} \
        --create --if-not-exists --topic {{ . }} \
        --partitions {{ $.Values.kafka.topicCreation.partitions }} \
        --replication-factor {{ $.Values.kafka.topicCreation.replicationFactor }}
      {{- end }}
{{- end -}}

{{/*
PostgreSQL password env value.
*/}}
{{- define "sentry.postgresPasswordEnvValue" -}}
{{- if .Values.postgres.password }}
valueFrom:
  secretKeyRef:
    name: {{ include "sentry.credentialsSecretName" . }}
    key: SENTRY_DB_PASSWORD
{{- else if .Values.postgres.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.postgres.existingSecret }}
    key: {{ .Values.postgres.existingSecretKey | default "password" }}
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
Redis password env value.
*/}}
{{- define "sentry.redisPasswordEnvValue" -}}
{{- if .Values.redis.password }}
valueFrom:
  secretKeyRef:
    name: {{ include "sentry.credentialsSecretName" . }}
    key: SENTRY_REDIS_PASSWORD
{{- else if .Values.redis.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.redis.existingSecret }}
    key: {{ .Values.redis.existingSecretKey | default "password" }}
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
ClickHouse password env value.
*/}}
{{- define "sentry.clickhousePasswordEnvValue" -}}
{{- if .Values.clickhouse.password }}
valueFrom:
  secretKeyRef:
    name: {{ include "sentry.credentialsSecretName" . }}
    key: CLICKHOUSE_PASSWORD
{{- else if .Values.clickhouse.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.clickhouse.existingSecret }}
    key: {{ .Values.clickhouse.existingSecretKey | default "password" }}
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
Initial admin password env value.
*/}}
{{- define "sentry.adminPasswordEnvValue" -}}
{{- if .Values.user.password }}
valueFrom:
  secretKeyRef:
    name: {{ include "sentry.credentialsSecretName" . }}
    key: SENTRY_ADMIN_PASSWORD
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
Sentry filestore S3 access key env value.
*/}}
{{- define "sentry.filestoreS3AccessKeyEnvValue" -}}
{{- if .Values.filestore.s3.accessKey }}
valueFrom:
  secretKeyRef:
    name: {{ include "sentry.credentialsSecretName" . }}
    key: SENTRY_FILESTORE_S3_ACCESS_KEY
{{- else if .Values.filestore.s3.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.filestore.s3.existingSecret }}
    key: {{ .Values.filestore.s3.existingSecretAccessKeyKey | default "SENTRY_FILESTORE_S3_ACCESS_KEY" }}
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
Sentry filestore S3 secret key env value.
*/}}
{{- define "sentry.filestoreS3SecretKeyEnvValue" -}}
{{- if .Values.filestore.s3.secretKey }}
valueFrom:
  secretKeyRef:
    name: {{ include "sentry.credentialsSecretName" . }}
    key: SENTRY_FILESTORE_S3_SECRET_KEY
{{- else if .Values.filestore.s3.existingSecret }}
valueFrom:
  secretKeyRef:
    name: {{ .Values.filestore.s3.existingSecret }}
    key: {{ .Values.filestore.s3.existingSecretSecretKeyKey | default "SENTRY_FILESTORE_S3_SECRET_KEY" }}
{{- else }}
value: ""
{{- end }}
{{- end -}}

{{/*
Sentry filestore S3 environment variables.
*/}}
{{- define "sentry.filestoreS3Env" -}}
{{- if eq .Values.filestore.backend "s3" }}
{{- if or .Values.filestore.s3.accessKey .Values.filestore.s3.existingSecret }}
- name: SENTRY_FILESTORE_S3_ACCESS_KEY
  {{- include "sentry.filestoreS3AccessKeyEnvValue" . | nindent 2 }}
{{- end }}
{{- if or .Values.filestore.s3.secretKey .Values.filestore.s3.existingSecret }}
- name: SENTRY_FILESTORE_S3_SECRET_KEY
  {{- include "sentry.filestoreS3SecretKeyEnvValue" . | nindent 2 }}
{{- end }}
- name: SENTRY_FILESTORE_S3_BUCKET_NAME
  value: {{ .Values.filestore.s3.bucketName | quote }}
{{- if .Values.filestore.s3.endpointUrl }}
- name: SENTRY_FILESTORE_S3_ENDPOINT_URL
  value: {{ .Values.filestore.s3.endpointUrl | quote }}
{{- end }}
- name: SENTRY_FILESTORE_S3_REGION
  value: {{ .Values.filestore.s3.region | quote }}
{{- end }}
{{- end -}}

{{/*
Web container image. Uses web.image if set, falls back to top-level image.
*/}}
{{- define "sentry.webImage" -}}
{{- $repo := .Values.web.image.repository -}}
{{- $tag := .Values.web.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.sentry.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.sentry.tag -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Worker container image. Uses worker.image if set, falls back to top-level image.
*/}}
{{- define "sentry.workerImage" -}}
{{- $repo := .Values.worker.image.repository -}}
{{- $tag := .Values.worker.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.sentry.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.sentry.tag -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Relay container image. Uses relay.image if set, falls back to image.relay.
*/}}
{{- define "sentry.relayImage" -}}
{{- $repo := .Values.relay.image.repository -}}
{{- $tag := .Values.relay.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.relay.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.relay.tag -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Snuba container image. Uses snuba.image if set, falls back to image.snuba.
*/}}
{{- define "sentry.snubaImage" -}}
{{- $repo := .Values.snuba.image.repository -}}
{{- $tag := .Values.snuba.image.tag -}}
{{- if not $repo -}}
{{- $repo = .Values.image.snuba.repository -}}
{{- end -}}
{{- if not $tag -}}
{{- $tag = .Values.image.snuba.tag -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
ServiceAccount name.
*/}}
{{- define "sentry.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "sentry.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL connection string.
*/}}
{{- define "sentry.databaseUrl" -}}
{{- printf "postgresql://%s:%s@%s:%d/%s" .Values.postgres.user .Values.postgres.password .Values.postgres.host (int .Values.postgres.port) .Values.postgres.database -}}
{{- end -}}
