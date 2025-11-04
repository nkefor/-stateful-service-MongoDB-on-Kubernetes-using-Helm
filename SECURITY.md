# Security Guidelines

This repo ships a demo stack. Use these practices for production hardening:

- Secrets
  - Never commit credentials. Use `kubectl create secret` or a secrets manager (SealedSecrets or External Secrets) and KMS-backed keys.
  - Rotate MongoDB root/app passwords regularly. Restrict who can read `Secret` objects.

- Identity & RBAC
  - Use least-privilege RBAC. ServiceAccounts should have only needed verbs on required resources.
  - Prefer per-namespace ServiceAccounts; avoid running workloads as `default` SA.

- Network & Ingress
  - Enforce network segmentation with NetworkPolicies (default deny + explicit allow).
  - Terminate TLS at ingress with cert-manager; enable HSTS and redirect HTTP→HTTPS.
  - Optionally add WAF and rate limits on ingress.

- Workload Hardening
  - Run as non-root, read-only root FS, drop capabilities; set seccomp/apparmor profiles.
  - Configure liveness/readiness probes, resource requests/limits, and HPA as applicable.
  - Use PodDisruptionBudgets for critical replicas.

- Supply Chain & Images
  - Pin image tags (no `:latest`). Enable Renovate to PR updates.
  - Scan images for CVEs (Trivy/Grype) in CI; fail on high/critical severity.
  - Verify provenance/signatures (Sigstore Cosign) where possible.

- Dependencies & Charts
  - Pin Helm chart versions (see `versions.env`). Review diff on upgrades.
  - Validate manifests with kubeconform and admission policies (OPA/Gatekeeper or Kyverno).

- Backups & DR
  - Automate backups (CronJobs) to versioned object storage. Encrypt at rest.
  - Test restores regularly and document RPO/RTO.

- Observability
  - Centralize logs/metrics (e.g., Prometheus/Grafana). Alert on pod restarts, replica health, cert expiry.
  - Enable audit logs on the API server if available and ship to SIEM.

- Platform Hygiene
  - Keep the cluster, CNI, and nodes patched. Automate node OS and Kubernetes version upgrades.
  - Restrict public access to the API server. Use SSO/MFA for admins.

Repo-specific notes
- NetworkPolicies included: default deny for `data`, allow `tools`→MongoDB:27017.
- TLS hardening added via ingress annotations (HSTS + redirect). Ensure DNS and ACME HTTP-01 reachability.
- CI enforces pinned images, validates YAML, and checks schema. Consider adding image scans.
- Scripts avoid storing secrets; use patch scripts to insert values locally, then create runtime `Secret`s.

Operational checklist
- Replace placeholder passwords and S3 settings; create secrets via `kubectl`.
- Confirm metrics-server installed for HPA.
- Set up Renovate for automated dependency PRs.
- Add image scanning to CI if required by policy.
