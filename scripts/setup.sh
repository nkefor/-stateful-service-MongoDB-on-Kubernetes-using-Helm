#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="${1:-}"
if [[ -z "$HOSTNAME" ]]; then
  echo "Usage: $0 <host> [data-ns] [tools-ns]" >&2
  exit 1
fi

DATA_NS="${2:-data}"
TOOLS_NS="${3:-tools}"
INGRESS_NS="ingress-nginx"
RELEASE="mongo"
VALUES="k8s/mongodb-values.yaml"

# Load pinned versions if present
if [[ -f versions.env ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' versions.env | xargs -d '\n')
fi

HELM_INGRESS_NGINX_CHART_VERSION="${HELM_INGRESS_NGINX_CHART_VERSION:-}"
HELM_MONGODB_CHART_VERSION="${HELM_MONGODB_CHART_VERSION:-}"

run() { echo "→ $*"; eval "$@"; }

echo "Installing NGINX Ingress Controller..."
run helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
run helm repo update
run kubectl create ns "$INGRESS_NS" --dry-run=client -o yaml | kubectl apply -f -
if [[ -n "${HELM_INGRESS_NGINX_CHART_VERSION}" ]]; then
  run helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n "$INGRESS_NS" --version "$HELM_INGRESS_NGINX_CHART_VERSION"
else
  run helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n "$INGRESS_NS"
fi

echo "Deploying MongoDB (Bitnami) with persistence..."
run helm repo add bitnami https://charts.bitnami.com/bitnami
run helm repo update
run kubectl create ns "$DATA_NS" --dry-run=client -o yaml | kubectl apply -f -
if [[ -n "${HELM_MONGODB_CHART_VERSION}" ]]; then
  run helm upgrade --install "$RELEASE" bitnami/mongodb -n "$DATA_NS" -f "$VALUES" --version "$HELM_MONGODB_CHART_VERSION"
else
  run helm upgrade --install "$RELEASE" bitnami/mongodb -n "$DATA_NS" -f "$VALUES"
fi

echo "Waiting for MongoDB pods to become Ready..."
kubectl wait --for=condition=Ready pod -n "$DATA_NS" -l app.kubernetes.io/name=mongodb --timeout=600s

echo "Installing metrics-server (for HPA) if not present..."
if ! kubectl get deploy -n kube-system metrics-server >/dev/null 2>&1; then
  run kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
fi

echo "Configuring secrets and deploying Mongo Express..."
ROOTPW=$(kubectl get secret -n "$DATA_NS" ${RELEASE}-mongodb -o jsonpath='{.data.mongodb-root-password}' | base64 -d)
run kubectl create ns "$TOOLS_NS" --dry-run=client -o yaml | kubectl apply -f -
run kubectl create secret generic mongo-root -n "$TOOLS_NS" --from-literal=password="$ROOTPW" --dry-run=client -o yaml | kubectl apply -f -

run kubectl apply -f k8s/mongo-express.yaml

echo "Applying HPA for Mongo Express..."
run kubectl apply -f k8s/mongo-express-hpa.yaml

echo "Patching Ingress host: $HOSTNAME"
tmp=$(mktemp)
sed -E "s/host: .*/host: $HOSTNAME/" k8s/mongo-express-ingress.yaml > "$tmp"
mv "$tmp" k8s/mongo-express-ingress.yaml
run kubectl apply -f k8s/mongo-express-ingress.yaml

echo "Done. Useful info:"
kubectl get svc -n "$INGRESS_NS" ingress-nginx-controller || true
kubectl get deploy,po,svc -n "$TOOLS_NS" || true
