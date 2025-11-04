# Usage Guide

A concise, copy-paste friendly guide to deploy, verify, and operate the MongoDB replica set + Mongo Express stack.

## Table of Contents
- Prerequisites
- One-time configuration
- Deploy (local scripts)
- Enable TLS
- Verify health
- Multi-environment with Kustomize
- Backups
- CI/CD configuration (GitHub Actions)
- Troubleshooting
- Cleanup

## Prerequisites
- A working Kubernetes cluster (Linode LKE recommended)
- `kubectl` and `helm` installed; kubeconfig points to your cluster
- A DNS hostname you control (for TLS and ingress)

## One-time configuration
Replace placeholders using the patch script (recommended) or edit files manually.

Linux/macOS:
```
bash scripts/patch-config.sh \
  --prod-host prod.example.com \
  --dev-host dev.example.com \
  --email you@example.com \
  --mongo-root 'StrongRoot#Pass123' \
  --mongo-app-user appuser \
  --mongo-app-pass 'StrongApp#Pass456' \
  --s3-endpoint https://us-east-1.linodeobjects.com \
  --s3-bucket s3://my-bucket/mongo-dumps
```

Windows PowerShell:
```
pwsh -File scripts/patch-config.ps1 \
  -ProdHost prod.example.com -DevHost dev.example.com -Email you@example.com \
  -MongoRoot 'StrongRoot#Pass123' -MongoAppUser appuser -MongoAppPass 'StrongApp#Pass456' \
  -S3Endpoint 'https://us-east-1.linodeobjects.com' -S3Bucket 's3://my-bucket/mongo-dumps'
```

## Deploy (local scripts)
```
# installs ingress-nginx, deploys MongoDB (Helm) + Mongo Express, metrics-server, and HPA
bash scripts/setup.sh prod.example.com
```

PowerShell:
```
pwsh -File scripts/setup.ps1 -HostName prod.example.com
```

## Enable TLS
```
# installs cert-manager, applies ClusterIssuer, patches Ingress for TLS
bash scripts/tls-setup.sh prod.example.com you@example.com
```

PowerShell:
```
pwsh -File scripts/tls-setup.ps1 -HostName prod.example.com -Email you@example.com
```

## Verify health
```
# curls the ingress address with the correct Host header until 2xx/3xx
bash scripts/health-check.sh prod.example.com
```
Then browse: `https://prod.example.com` (basic auth from `mongo-express-auth` secret in `tools` namespace).

## Multi-environment with Kustomize
```
# prod
bash scripts/deploy-kustomize.sh k8s/overlays/prod
# dev
bash scripts/deploy-kustomize.sh k8s/overlays/dev
```

## Backups
- Edit `k8s/backup/mongo-backup-cronjob.yaml` to provide S3 credentials securely (or create the Secret via `kubectl`).
- Apply CronJob:
```
kubectl apply -f k8s/backup/mongo-backup-cronjob.yaml
```

## CI/CD configuration (GitHub Actions)
- Add repo secrets:
  - `KUBE_CONFIG_B64`: base64-encoded kubeconfig for your cluster
  - `INGRESS_HOST`: your production host
  - `CERT_EMAIL`: your ACME email
- Optional: adjust chart versions in `versions.env`.
- Trigger deploy from Actions → "Deploy to LKE" (or push to main affecting `k8s/**` or `scripts/**`).

## Troubleshooting
- Ingress has no external IP: check your cloud provider’s LoadBalancer support.
- TLS issuance fails: verify DNS resolves and that port 80 is reachable for HTTP-01.
- PVC pending: validate StorageClass and node provisioning.
- HPA idle: ensure `metrics-server` is running in `kube-system`.
- Backups failing: confirm S3 endpoint/bucket and credentials; inspect CronJob pod logs.

## Cleanup
```
# remove app, ingress, MongoDB, and ingress controller
bash scripts/teardown.sh
# PowerShell
pwsh -File scripts/teardown.ps1
```
