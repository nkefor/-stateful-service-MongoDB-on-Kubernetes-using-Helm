# MongoDB on Kubernetes (LKE) via Helm

This folder contains ready-to-apply manifests and Helm values to deploy:
- Bitnami MongoDB (replica set) with Linode block storage persistence
- Mongo Express UI
- NGINX Ingress to expose the UI

## Prerequisites
- LKE cluster and kubeconfig as current context
- `kubectl` and `helm` installed
- NGINX Ingress Controller installed (see commands below)

## Quick Start

1) Install NGINX Ingress Controller:
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create ns ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

2) Deploy MongoDB (replica set) using Bitnami chart:
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create ns data || true
helm upgrade --install mongo bitnami/mongodb -n data -f k8s/mongodb-values.yaml
kubectl get pods -n data -l app.kubernetes.io/name=mongodb
kubectl get pvc -n data
```

3) Set up Mongo Express secrets and deploy UI:
```
# pull Mongo root password into tools namespace
ROOTPW=$(kubectl get secret -n data mongo-mongodb -o jsonpath='{.data.mongodb-root-password}' | base64 -d)
kubectl create namespace tools || true
kubectl create secret generic mongo-root -n tools --from-literal=password="$ROOTPW" --dry-run=client -o yaml | kubectl apply -f -

# deploy Mongo Express
kubectl apply -f k8s/mongo-express.yaml
kubectl get deploy,po,svc -n tools
```

4) Expose Mongo Express via Ingress:
```
# edit k8s/mongo-express-ingress.yaml and set your host (mongo-ui.example.com)
kubectl apply -f k8s/mongo-express-ingress.yaml
```

5) Browse to your host. If you don’t have DNS yet, map the NGINX controller external IP in your hosts file.

## Cleanup
```
kubectl delete -f k8s/mongo-express-ingress.yaml || true
kubectl delete -f k8s/mongo-express.yaml || true
helm uninstall mongo -n data || true
kubectl delete ns tools data || true
helm uninstall ingress-nginx -n ingress-nginx || true
kubectl delete ns ingress-nginx || true
```

## Notes
- StorageClass: uses `linode-block-storage-retain` for safer recovery.
- Mongo Express basic auth is configured via `mongo-express-auth` secret in `tools` namespace.
- Scale MongoDB carefully; modify `replicaCount` in values and run `helm upgrade`.
  - For disruption tolerance, the values file enables a PodDisruptionBudget with `minAvailable: 2` for the replica set. Tune based on your SLOs.

## Security & Operability Additions
- NetworkPolicies: Default deny in `data` and allow only `tools` namespace to reach MongoDB on port 27017.
  - Apply: `kubectl apply -f k8s/networkpolicy-data-deny-all.yaml -f k8s/networkpolicy-allow-tools-to-mongo.yaml`
- Probes & HPA: `k8s/mongo-express.yaml` includes readiness/liveness probes; `k8s/mongo-express-hpa.yaml` scales 1–5 on 70% CPU.
  - Apply HPA: `kubectl apply -f k8s/mongo-express-hpa.yaml`
- TLS hardening: Ingress now forces HTTPS and enables HSTS headers.
- Backups: CronJob in `k8s/backup/mongo-backup-cronjob.yaml` dumps Mongo and uploads to Linode Object Storage (S3-compatible).
  - Set `s3-credentials` Secret values (access key, secret, bucket, endpoint) before applying.
  - Apply: `kubectl apply -f k8s/backup/mongo-backup-cronjob.yaml`

## Multi-Env with Kustomize
- Base: `k8s/base/kustomization.yaml` aggregates app, ingress, HPA, network policies, and backup.
- Overlays: `k8s/overlays/dev` and `k8s/overlays/prod` patch the Ingress host and add env labels.
- Deploy an overlay:
  - `kubectl kustomize k8s/overlays/dev | kubectl apply -f -`
  - or use script: `bash scripts/deploy-kustomize.sh k8s/overlays/prod`

## Production Sizing & Storage Guidance
- Nodes: Prefer at least 3 worker nodes; size so that each MongoDB pod can land on a different node.
  - Start with 2–4 vCPU and 4–8 GiB RAM per node for small workloads; increase for higher working set sizes.
- Storage: Use Linode Block Storage with `linode-block-storage-retain`; provision 10–50 GiB+ per replica based on data growth.
  - For performance, avoid overcommitting; monitor IOPS/latency and consider larger volumes for higher baseline performance.
- Spreading and anti-affinity: Enabled in `k8s/mongodb-values.yaml` to avoid co-scheduling MongoDB replicas on the same node.
- Backups and restores: Test restores regularly; consider weekly full + daily incremental (or object storage versioning).
