#!/usr/bin/env bash
set -euo pipefail

OVERLAY_PATH="${1:-}"
if [[ -z "$OVERLAY_PATH" ]]; then
  echo "Usage: $0 <k8s/overlays/{dev|prod}>" >&2
  exit 1
fi

if ! command -v kubectl >/dev/null; then
  echo "kubectl not found" >&2
  exit 2
fi

echo "Building and applying kustomize overlay: $OVERLAY_PATH"
kubectl kustomize "$OVERLAY_PATH" | kubectl apply -f -
echo "Done."

