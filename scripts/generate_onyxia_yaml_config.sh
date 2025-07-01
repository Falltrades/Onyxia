#!/bin/bash

GITHUB_USERNAME=${GITHUB_USERNAME}
GITHUB_USERMAIL=${GITHUB_USERMAIL}
GIT_PERSONAL_TOKEN=${GIT_PERSONAL_TOKEN}
ONYXIA_DNS=${ONYXIA_DNS}
INTERNAL_DNS=${INTERNAL_DNS}
CLUSTER_PROXY=${CLUSTER_PROXY}
ONYXIA_CUSTOM_IMAGE=ghcr.io/cloud-pi-native/onyxia-custom:1
RANDOM_NUMBER=$(printf "%05d" $(( RANDOM % 100000 )))
RANDOM_PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
INTERNAL_TELEPORT=${INTERNAL_TELEPORT}
PUBLIC_TELEPORT=${PUBLIC_TELEPORT}
PUBLIC_TELEPORT2=${PUBLIC_TELEPORT2}
GITOPS_REPO_BASE_PATH=${GITOPS_REPO_BASE_PATH}
TP_USER=${TP_USER}

cat <<EOF> onyxia_custom_config.yaml
service:
  image:
    pullPolicy: IfNotPresent
    version: inseefrlab/onyxia-vscode-python:py3.13.8
    custom:
      enabled: true
      version: ${ONYXIA_CUSTOM_IMAGE} 
init:
  regionInit: ""
  personalInit: https://raw.githubusercontent.com/Falltrades/Onyxia/refs/heads/main/scripts/post-install-light.sh
  personalInitArgs: "" 
extraEnvVars:
  - name: GITHUB_USERNAME
    value: ${GITHUB_USERNAME} 
  - name: GITHUB_USERMAIL
    value: ${GITHUB_USERMAIL} 
  - name: INTERNAL_TELEPORT
    value: ${INTERNAL_TELEPORT} 
  - name: PUBLIC_TELEPORT
    value: ${PUBLIC_TELEPORT} 
  - name: PUBLIC_TELEPORT2
    value: ${PUBLIC_TELEPORT2}
  - name: INTERNAL_GITOPS_REPO_BASE_PATH
    value: ${INTERNAL_GITOPS_REPO_BASE_PATH}
  - name: PUBLIC_GITOPS_REPO_BASE_PATH
    value: ${PUBLIC_GITOPS_REPO_BASE_PATH}
  - name: TP_USER 
    value: ${TP_USER} 
  - name: TP_BASTION_SSL_CERT
    value: ${TP_BASTION_SSL_CERT} 
  - name: TP_CPIN_SSL_CERT2
    value: ${TP_CPIN_SSL_CERT2}
  - name: TP_CPIN_SSL_CERT
    value: ${TP_CPIN_SSL_CERT} 
  - name: CLUSTER_PROXY
    value: ${CLUSTER_PROXY}
  - name: VAULT_INFRA_DOMAIN
    value: ${VAULT_INFRA_DOMAIN}
  - name: VAULT_INFRA_TOKEN
    value: ${VAULT_INFRA_TOKEN}
  - name: GIT_SSL_NO_VERIFY
    value: "true"
git:
  enabled: true
  name: "${GITHUB_USERNAME}"
  email: ${GITHUB_USERMAIL} 
  cache: "0"
  token: "${GIT_PERSONAL_TOKEN}"
  repository: https://github.com/falltrades/onyxia.git 
  branch: ""
ingress:
  enabled: false
  hostname: user-${RANDOM_NUMBER}-0.dev.user.${ONYXIA_DNS}
  userHostname: user-${RANDOM_NUMBER}-user.dev.user.${ONYXIA_DNS}
  ingressClassName: ""
  useCertManager: false
  certManagerClusterIssuer: ""
route:
  enabled: true
  hostname: user-${RANDOM_NUMBER}-0.dev.user.${ONYXIA_DNS}
  userHostname: user-${RANDOM_NUMBER}-user.dev.user.${ONYXIA_DNS}
security:
  password: ${RANDOM_PASSWORD} 
  networkPolicy:
    enabled: false
    from: []
resources:
  requests:
    cpu: 200m
    memory: 500M
  limits:
    cpu: 2000m
    memory: 4000M
persistence:
  enabled: true
  size: 10Gi
kubernetes:
  enabled: true
  role: view
openshiftSCC:
  enabled: false
  scc: anyuid
vault:
  enabled: true
  token: ""
  url: ""
  mount: ""
  directory: ""
  secret: ""
s3:
  enabled: true
  accessKeyId: ""
  endpoint: ""
  defaultRegion: ""
  secretAccessKey: ""
  sessionToken: ""
  pathStyleAccess: false
  workingDirectoryPath: ""
networking:
  user:
    enabled: false
    port: 5000
    ports:
      - 5000
discovery:
  hive: true
  mlflow: true
  metaflow: true
  chromadb: true
  milvus: true
  postgresql: true
nodeSelector: {}
repository:
  pipRepository: ""
  condaRepository: ""
startupProbe:
  failureThreshold: 60
  initialDelaySeconds: 10
  periodSeconds: 10
  successThreshold: 1
  timeoutSeconds: 2
tolerations: []
userPreferences:
  darkMode: true
  language: fr
  aiAssistant:
    enabled: true
    model: llama3.3
    provider: ollama
    apiBase: https://ollama.${ONYXIA_DNS}
    useLegacyCompletionsEndpoint: true
global:
  suspend: false
proxy:
  enabled: true
  httpProxy: ${CLUSTER_PROXY}
  httpsProxy: ${CLUSTER_PROXY}
  noProxy: localhost,.cluster.local,kubernetes.default,.svc,172.30.0.1,.dev.user.${ONYXIA_DNS},${INTERNAL_DNS}
certificates:
  cacerts: http://config.dev.user.${ONYXIA_DNS}/pi.pem
  pathToCaBundle: /usr/local/share/ca-certificates/
message:
  fr: ""
  en: ""
EOF
