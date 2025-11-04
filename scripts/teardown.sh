#!/usr/bin/env bash
set -euo pipefail

DATA_NS="${1:-data}"
TOOLS_NS="${2:-tools}"
INGRESS_NS="${3:-ingress-nginx}"
RELEASE="${4:-mongo}"

run() { echo "→ $*"; eval "$@"; }

echo "Removing Ingress and Mongo Express..."
run kubectl delete -f k8s/mongo-express-ingress.yaml --ignore-not-found
run kubectl delete -f k8s/mongo-express.yaml --ignore-not-found

echo "Uninstalling MongoDB chart..."
run helm uninstall "$RELEASE" -n "$DATA_NS" || true
run kubectl delete ns "$TOOLS_NS" --ignore-not-found
run kubectl delete ns "$DATA_NS" --ignore-not-found

echo "Removing ingress controller..."
run helm uninstall ingress-nginx -n "$INGRESS_NS" || true
run kubectl delete ns "$INGRESS_NS" --ignore-not-found

echo "Teardown complete."

