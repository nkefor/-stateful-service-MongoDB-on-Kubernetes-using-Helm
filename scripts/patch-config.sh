#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash scripts/patch-config.sh \
#     --prod-host prod.example.com \
#     --dev-host dev.example.com \
#     --email you@example.com \
#     --mongo-root 'StrongRoot#Pass123' \
#     --mongo-app-user appuser \
#     --mongo-app-pass 'StrongApp#Pass456' \
#     --s3-endpoint https://us-east-1.linodeobjects.com \
#     --s3-bucket s3://my-bucket/mongo-dumps

PROD_HOST=""
DEV_HOST=""
EMAIL=""
MONGO_ROOT=""
MONGO_APP_USER=""
MONGO_APP_PASS=""
S3_ENDPOINT=""
S3_BUCKET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prod-host) PROD_HOST="$2"; shift 2;;
    --dev-host) DEV_HOST="$2"; shift 2;;
    --email) EMAIL="$2"; shift 2;;
    --mongo-root) MONGO_ROOT="$2"; shift 2;;
    --mongo-app-user) MONGO_APP_USER="$2"; shift 2;;
    --mongo-app-pass) MONGO_APP_PASS="$2"; shift 2;;
    --s3-endpoint) S3_ENDPOINT="$2"; shift 2;;
    --s3-bucket) S3_BUCKET="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

patch_file() { local f="$1"; shift; printf "→ Patching %s\n" "$f"; eval "$@"; }

# Ingress hosts (overlays)
if [[ -n "$PROD_HOST" ]]; then
  patch_file k8s/overlays/prod/ingress-host.yaml \
    "sed -i -E 's/(^\s*-\s)hosts:\n(\s*-\s).*/\1hosts:\n        - $PROD_HOST/' k8s/overlays/prod/ingress-host.yaml || true";
  sed -i -E "s/(^\s*-\s)host: .*/\1host: $PROD_HOST/" k8s/overlays/prod/ingress-host.yaml
fi
if [[ -n "$DEV_HOST" ]]; then
  patch_file k8s/overlays/dev/ingress-host.yaml \
    "sed -i -E 's/(^\s*-\s)hosts:\n(\s*-\s).*/\1hosts:\n        - $DEV_HOST/' k8s/overlays/dev/ingress-host.yaml || true";
  sed -i -E "s/(^\s*-\s)host: .*/\1host: $DEV_HOST/" k8s/overlays/dev/ingress-host.yaml
fi

# ACME email
if [[ -n "$EMAIL" ]]; then
  patch_file k8s/cert-manager-clusterissuer.yaml \
    "sed -i -E 's/^\s*email: .*/    email: $EMAIL/' k8s/cert-manager-clusterissuer.yaml"
fi

# MongoDB credentials in values
if [[ -n "$MONGO_ROOT" ]]; then
  patch_file k8s/mongodb-values.yaml \
    "sed -i -E 's/^\s*rootPassword: .*/  rootPassword: '$MONGO_ROOT'/' k8s/mongodb-values.yaml"
fi
if [[ -n "$MONGO_APP_USER" ]]; then
  patch_file k8s/mongodb-values.yaml \
    "sed -i -E 's/^\s*- appuser/    - '$MONGO_APP_USER'/' k8s/mongodb-values.yaml"
fi
if [[ -n "$MONGO_APP_PASS" ]]; then
  patch_file k8s/mongodb-values.yaml \
    "sed -i -E 's/^\s*- CHANGEME-APP/    - '$MONGO_APP_PASS'/' k8s/mongodb-values.yaml"
fi

# Backup endpoint and bucket (leave access keys to user)
if [[ -n "$S3_ENDPOINT" ]]; then
  patch_file k8s/backup/mongo-backup-cronjob.yaml \
    "sed -i -E 's#^(\s*S3_ENDPOINT: ).*#\1"'$S3_ENDPOINT'"#' k8s/backup/mongo-backup-cronjob.yaml"
fi
if [[ -n "$S3_BUCKET" ]]; then
  patch_file k8s/backup/mongo-backup-cronjob.yaml \
    "sed -i -E 's#^(\s*S3_BUCKET: ).*#\1"'$S3_BUCKET'"#' k8s/backup/mongo-backup-cronjob.yaml"
fi

echo "Config patching complete. Review git diff and commit changes."

