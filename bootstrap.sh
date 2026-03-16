#!/bin/bash

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-todoapp}"
CHART_PATH=".infrastructure/helm-chart/todoapp"
RELEASE_NAME="${RELEASE_NAME:-todoapp}"
INGRESS_MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-8080}"
HOST_HTTPS_PORT="${HOST_HTTPS_PORT:-8443}"
HOST_NODEPORT_APP="${HOST_NODEPORT_APP:-31007}"
HOST_NODEPORT_EXTRA="${HOST_NODEPORT_EXTRA:-31008}"
TMP_CLUSTER_CONFIG="$(mktemp)"

cleanup() {
  rm -f "${TMP_CLUSTER_CONFIG}"
}

trap cleanup EXIT

sed \
  -e "s/hostPort: 30007/hostPort: ${HOST_NODEPORT_APP}/" \
  -e "s/hostPort: 30008/hostPort: ${HOST_NODEPORT_EXTRA}/" \
  -e "s/hostPort: 80/hostPort: ${HOST_HTTP_PORT}/" \
  -e "s/hostPort: 443/hostPort: ${HOST_HTTPS_PORT}/" \
  cluster.yml > "${TMP_CLUSTER_CONFIG}"

kind get clusters | grep -qx "${CLUSTER_NAME}" || kind create cluster --name "${CLUSTER_NAME}" --config "${TMP_CLUSTER_CONFIG}"

kubectl cluster-info

kubectl get nodes -l app=mysql -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | xargs -r -I{} kubectl taint nodes {} app=mysql:NoSchedule --overwrite

kubectl apply -f "${INGRESS_MANIFEST_URL}"
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

helm dependency update "${CHART_PATH}"
helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" -f "${CHART_PATH}/values.yaml" --create-namespace

kubectl rollout status statefulset/mysql -n mysql --timeout=180s
kubectl rollout status deployment/todoapp -n todoapp --timeout=180s

kubectl get all,cm,secret,ing -A > output.log
