#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"
if [[ -z "$HOST" ]]; then
  echo "Usage: $0 <host>" >&2
  exit 1
fi

NAMESPACE="ingress-nginx"
PATH_TO_CHECK="/"
RETRIES=30
SLEEP=10

echo "Resolving ingress controller address..."
IP=$(kubectl get svc -n "$NAMESPACE" ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true)
HN=$(kubectl get svc -n "$NAMESPACE" ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || true)

ADDR=${IP:-$HN}
if [[ -z "$ADDR" ]]; then
  echo "Could not find ingress controller address." >&2
  exit 2
fi

echo "Using ingress address: $ADDR (Host: $HOST)"

for i in $(seq 1 $RETRIES); do
  echo "[Attempt $i/$RETRIES] GET http://$ADDR$PATH_TO_CHECK with Host header $HOST"
  if curl -ksS -H "Host: $HOST" -o /dev/null -w "%{http_code}\n" "http://$ADDR$PATH_TO_CHECK" | grep -E '^(2|3)[0-9]{2}$' >/dev/null; then
    echo "Health check passed."
    exit 0
  fi
  sleep "$SLEEP"
done

echo "Health check failed after $RETRIES attempts." >&2
exit 3

