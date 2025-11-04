#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="${1:-}"
EMAIL="${2:-}"
INGRESS_NS="${3:-ingress-nginx}"

if [[ -z "$HOSTNAME" || -z "$EMAIL" ]]; then
  echo "Usage: $0 <host> <email> [ingress-ns]" >&2
  exit 1
fi

run() { echo "→ $*"; eval "$@"; }

echo "Installing cert-manager via Helm..."
run helm repo add jetstack https://charts.jetstack.io
run helm repo update
run kubectl create ns cert-manager --dry-run=client -o yaml | kubectl apply -f -
HELM_CERT_MANAGER_CHART_VERSION="${HELM_CERT_MANAGER_CHART_VERSION:-}"

if [[ -f versions.env ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' versions.env | xargs -d '\n')
fi

if [[ -n "${HELM_CERT_MANAGER_CHART_VERSION}" ]]; then
  run helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true \
  --version "$HELM_CERT_MANAGER_CHART_VERSION"
else
  run helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true
fi

echo "Applying ClusterIssuer (email=$EMAIL)..."
tmp=$(mktemp)
sed -E "s/email: .*/email: $EMAIL/" k8s/cert-manager-clusterissuer.yaml > "$tmp"
kubectl apply -f "$tmp"
rm -f "$tmp"

echo "Patching Ingress host + enabling TLS... ($HOSTNAME)"
tmp=$(mktemp)
sed -E "s/host: .*/host: $HOSTNAME/; s/hosts:\n\s*- .*/hosts:\n        - $HOSTNAME/" k8s/mongo-express-ingress.yaml > "$tmp"
mv "$tmp" k8s/mongo-express-ingress.yaml
run kubectl apply -f k8s/mongo-express-ingress.yaml

echo "Waiting for certificate to be issued..."
kubectl -n tools wait --for=condition=Ready certificate/mongo-express-tls --timeout=600s || true
kubectl -n tools get certificate,order,challenge || true

echo "TLS setup complete."
