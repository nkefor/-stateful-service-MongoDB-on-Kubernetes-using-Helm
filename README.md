# Stateful MongoDB on Kubernetes using Helm (LKE)

![Demo GIF placeholder](docs/demo.gif)

Tip: Replace `docs/demo.gif` with a short screencast of setup → TLS → UI access. See "Optional Screencast / Animations" below.

Enterprise-style reference to deploy a stateful service (MongoDB replica set) on Kubernetes with:
- Helm (Bitnami MongoDB), Mongo Express UI
- NGINX Ingress + cert-manager (Let’s Encrypt TLS)
- Linode LKE and Block Storage
- NetworkPolicies, HPA, backups to S3-compatible storage
- CI/CD via GitHub Actions; Kustomize overlays (dev/prod)

## Architecture

```mermaid
flowchart LR
  User -->|HTTPS| Ingress[NGINX Ingress]
  Ingress --> SVC[Service tools/mongo-express]
  SVC --> UI[Mongo Express Pod]
  UI -->|27017| RS[(MongoDB ReplicaSet)]
  subgraph data Namespace
    RS -.-> PVC1[(PV/PVC)]
    RS -.-> PVC2[(PV/PVC)]
    RS -.-> PVC3[(PV/PVC)]
  end
  note right of Ingress: cert-manager issues TLS via ACME HTTP-01
  note bottom of RS: Linode Block Storage provides persistence
```

NetworkPolicies default‑deny in `data` and allow only `tools` -> MongoDB:27017. HPA scales Mongo Express by CPU. A nightly CronJob uploads mongodump archives to Linode Object Storage.

## What’s Included
- `k8s/`
  - `mongodb-values.yaml` (replicaset, persistence, PDB, anti‑affinity, spread)
  - `mongo-express.yaml` (Deployment/Service with probes)
  - `mongo-express-ingress.yaml` (TLS, HTTPS redirect, HSTS)
  - `mongo-express-hpa.yaml` (CPU autoscaling 1–5)
  - `networkpolicy-*.yaml` (default deny + allow tools→Mongo)
  - `backup/mongo-backup-cronjob.yaml` (mongodump → object storage)
  - `base/` and `overlays/{dev,prod}/` (Kustomize)
- `scripts/`
  - `setup.(sh|ps1)` ingress, MongoDB Helm install, Mongo Express, metrics‑server, HPA
  - `tls-setup.(sh|ps1)` cert‑manager + ClusterIssuer, TLS patch
  - `health-check.sh` curl ingress with Host header
  - `deploy-kustomize.sh` apply dev/prod overlays
  - `patch-config.(sh|ps1)` patch hosts, ACME email, Mongo creds, backup settings
  - `teardown.(sh|ps1)` cleanup
- `.github/workflows/`
  - `deploy.yaml` deploy + TLS + overlay + health check
  - `lint-validate.yaml` yamllint, shellcheck, shfmt, PSScriptAnalyzer, kubeconform
- `versions.env` pinned Helm chart versions; `SECURITY.md` hardening

## Real‑World Scenarios
- Team staging data service with TLS and restricted access.
- Training/demo clusters needing repeatable setup/teardown.
- Baseline pattern for stateful workloads: ingress, TLS, persistence, policies, backups.

## Prerequisites
- LKE cluster (or any K8s with a compatible StorageClass and external LoadBalancer)
- `kubectl` and `helm`; kubeconfig set to target cluster
- Domain for ingress host; DNS A‑record to ingress controller external IP
- Optional: GitHub Actions and `gh` CLI for metadata

## End‑to‑End Steps
1) Configure values (safe patch)
   - `bash scripts/patch-config.sh --prod-host prod.example.com --dev-host dev.example.com --email you@example.com --mongo-root 'StrongRoot#Pass123' --mongo-app-user appuser --mongo-app-pass 'StrongApp#Pass456' --s3-endpoint https://us-east-1.linodeobjects.com --s3-bucket s3://my-bucket/mongo-dumps`
2) Install base components
   - `bash scripts/setup.sh prod.example.com`
   - Installs ingress-nginx, MongoDB (Helm), Mongo Express, metrics‑server, HPA
3) Enable TLS
   - `bash scripts/tls-setup.sh prod.example.com you@example.com`
   - Installs cert‑manager, applies ClusterIssuer, patches ingress for TLS
4) Verify
   - `bash scripts/health-check.sh prod.example.com`
   - Browse: `https://prod.example.com` (basic auth from `mongo-express-auth` secret)
5) Multi‑env via Kustomize
   - `bash scripts/deploy-kustomize.sh k8s/overlays/prod`
   - For dev: `bash scripts/deploy-kustomize.sh k8s/overlays/dev`
6) Backups
   - Edit credentials in `k8s/backup/mongo-backup-cronjob.yaml` Secret (or create via kubectl)
   - `kubectl apply -f k8s/backup/mongo-backup-cronjob.yaml`
7) Cleanup
   - `bash scripts/teardown.sh` (or PowerShell equivalents)

## CI/CD Overview

```mermaid
flowchart TD
  Push[Push/Dispatch] --> Deploy
  Deploy --> Helm[Setup: ingress, MongoDB, Express]
  Helm --> TLS[tls-setup: cert-manager + ClusterIssuer]
  TLS --> Kustomize[Apply overlay (dev/prod)]
  Kustomize --> Health[Ingress health check]
```

Validation workflow lints YAML and scripts, checks schema with kubeconform, enforces pinned image tags, and verifies chart versions from `versions.env`.

Security add-on: the CI also scans container images referenced in the manifests using Trivy and fails the build on HIGH/CRITICAL CVEs.

## Troubleshooting
- Ingress pending/no IP: ensure your cloud provides an external LoadBalancer and security rules allow 80/443.
- TLS fails: verify DNS resolves to the ingress IP and that HTTP‑01 path is reachable.
- PVC pending: confirm StorageClass (`linode-block-storage-retain`) exists and has capacity.
- HPA no scale: ensure `metrics-server` is running in `kube-system`.
- Backups: verify S3 endpoint/bucket and credentials; check CronJob logs.

## Optional Screencast / Animations
- Record a short terminal demo (deploy + browse) with asciinema:
  - `pip install asciinema` or `brew install asciinema`
  - `asciinema rec` → run setup/tls scripts and exit to save the cast
- Convert to GIF for README using agg:
  - `npm i -g asciicast2gif` and `asciicast2gif <cast.json> out.gif` (requires Docker or ImageMagick)
- Add screenshots of the Mongo Express UI and link the GIF at the top of the README if desired.

## Set GitHub Description and Topics
- With GitHub CLI (`gh`):
  - `gh repo edit --description "Stateful MongoDB on Kubernetes using Helm, with TLS, NetworkPolicies, HPA, backups, Kustomize, and CI/CD" --add-topic kubernetes --add-topic helm --add-topic mongodb --add-topic devops --add-topic cicd --add-topic linode --add-topic ingress --add-topic cert-manager`
- Or use helper scripts in `scripts/` (requires `gh`):
  - `bash scripts/gh-set-repo-meta.sh "Stateful MongoDB on Kubernetes using Helm..." kubernetes,helm,mongodb,devops,cicd,linode,ingress,cert-manager`

## Security
See `SECURITY.md` for hardening: secrets handling, RBAC, NetworkPolicies, TLS, probes/limits/HPA, pinned images, image scanning, backups/DR, and platform hygiene.
