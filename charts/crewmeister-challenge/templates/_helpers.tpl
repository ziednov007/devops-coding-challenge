{{- define "crewmeister-challenge.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "crewmeister-challenge.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "crewmeister-challenge.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "crewmeister-challenge.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "crewmeister-challenge.selectorLabels" -}}
app.kubernetes.io/name: {{ include "crewmeister-challenge.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
