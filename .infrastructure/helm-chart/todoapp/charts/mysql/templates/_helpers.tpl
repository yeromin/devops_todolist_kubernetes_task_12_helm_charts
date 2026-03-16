{{- define "mysql.namespace" -}}
{{- .Values.namespace.name -}}
{{- end -}}

{{- define "mysql.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "mysql.secretName" -}}
{{- printf "%s-secrets" .Chart.Name -}}
{{- end -}}

{{- define "mysql.configMapName" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "mysql.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
