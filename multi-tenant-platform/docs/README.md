# Multi-Tenant DevSecOps Platform on Kubernetes

A production-ready, enterprise-grade multi-tenant platform that provides secure isolation, GitOps-driven deployments, policy enforcement, and comprehensive observability for Kubernetes workloads.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Core Components](#core-components)
- [Tenant Model](#tenant-model)
- [Security Architecture](#security-architecture)
- [Getting Started](#getting-started)
- [Platform Operations](#platform-operations)
- [Tenant Operations](#tenant-operations)
- [Observability](#observability)
- [Policy Enforcement](#policy-enforcement)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Multi-Tenant DevSecOps Platform                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Tenant A   │  │   Tenant B   │  │   Tenant C   │  │   Tenant N   │    │
│  │              │  │              │  │              │  │              │    │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │    │
│  │ │   Dev    │ │  │ │   Dev    │ │  │ │   Dev    │ │  │ │   Dev    │ │    │
│  │ ├──────────┤ │  │ ├──────────┤ │  │ ├──────────┤ │  │ ├──────────┤ │    │
│  │ │ Staging  │ │  │ │ Staging  │ │  │ │ Staging  │ │  │ │ Staging  │ │    │
│  │ ├──────────┤ │  │ ├──────────┤ │  │ ├──────────┤ │  │ ├──────────┤ │    │
│  │ │   Prod   │ │  │ │   Prod   │ │  │ │   Prod   │ │  │ │   Prod   │ │    │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                 │                 │                 │            │
│         └─────────────────┴─────────────────┴─────────────────┘            │
│                                    │                                        │
├────────────────────────────────────┼────────────────────────────────────────┤
│                           Platform Layer                                    │
│  ┌─────────────┐  ┌─────────────┐  │  ┌─────────────┐  ┌─────────────┐     │
│  │   ArgoCD    │  │   Kyverno   │  │  │ Prometheus  │  │    Loki     │     │
│  │   GitOps    │  │   Policies  │  │  │   Metrics   │  │    Logs     │     │
│  └─────────────┘  └─────────────┘  │  └─────────────┘  └─────────────┘     │
│                                    │                                        │
│  ┌─────────────┐  ┌─────────────┐  │  ┌─────────────┐  ┌─────────────┐     │
│  │   Capsule   │  │ Cert-Manager│  │  │   Grafana   │  │Alertmanager │     │
│  │   Tenants   │  │     TLS     │  │  │ Dashboards  │  │   Alerts    │     │
│  └─────────────┘  └─────────────┘  │  └─────────────┘  └─────────────┘     │
│                                    │                                        │
├────────────────────────────────────┼────────────────────────────────────────┤
│                        Kubernetes Cluster                                   │
│  ┌─────────────────────────────────┴─────────────────────────────────┐     │
│  │  Namespaces │ RBAC │ NetworkPolicies │ ResourceQuotas │ PSS/PSA   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Tenant Isolation Layer
- **Namespace-based isolation**: Each tenant gets dedicated namespaces per environment
- **Capsule integration**: Optional Capsule operator for enhanced multi-tenancy
- **NetworkPolicies**: Default-deny with explicit allow rules per tenant
- **Resource Quotas**: Tier-based resource limits enforced at namespace level

### 2. Identity & Access Management
- **Platform roles**: Admin, Operator, Viewer with cluster-wide permissions
- **Tenant roles**: Admin, Developer, Viewer scoped to tenant namespaces
- **CI/CD service accounts**: Dedicated accounts for automation pipelines
- **SSO integration**: OAuth2/OIDC support for enterprise identity providers

### 3. GitOps & Deployment
- **ArgoCD**: Declarative GitOps with multi-tenant AppProjects
- **Per-tenant projects**: Isolated Git repos and deployment permissions
- **Sync policies**: Automated sync with pruning and self-healing
- **ApplicationSets**: Multi-environment deployments from single source

### 4. Policy Enforcement
- **Kyverno policies**: Admission control and mutation policies
- **Pod Security Standards**: Restricted security profile enforcement
- **Image policies**: Registry restrictions and tag requirements
- **Resource policies**: Mandatory labels, limits, and probes

### 5. Observability
- **Prometheus**: Multi-tenant metrics collection with tenant labels
- **Loki**: Centralized logging with tenant-based retention
- **Grafana**: Tenant-scoped dashboards and self-service views
- **Alertmanager**: Tenant-aware alert routing and escalation

## Tenant Model

### Service Tiers

| Feature | Free | Starter | Professional | Enterprise |
|---------|------|---------|--------------|------------|
| Max Namespaces | 2 | 5 | 15 | 50 |
| CPU Requests | 2 cores | 8 cores | 32 cores | 128 cores |
| Memory | 4Gi | 16Gi | 64Gi | 256Gi |
| Storage | 10Gi | 50Gi | 200Gi | 1Ti |
| Max Pods | 20 | 50 | 200 | 1000 |
| LoadBalancers | No | 1 | 5 | 20 |
| Custom Domains | No | Yes | Yes | Yes |
| GitOps | Yes | Yes | Yes | Yes |
| Alerting | No | Yes | Yes | Yes |
| Metrics Retention | 3 days | 7 days | 30 days | 90 days |
| SLA | Best-effort | Standard | Business | Enterprise |

### Tenant Lifecycle

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Onboarding │ ──▶ │   Active    │ ──▶ │  Suspended  │ ──▶ │ Offboarded  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
  - Create NS         - Deploy apps      - Restrict access    - Backup data
  - Setup RBAC        - Scale workloads  - Notify tenant      - Delete NS
  - Apply quotas      - Monitor usage    - Grace period       - Archive logs
  - Create GitOps     - Receive alerts                        - Remove RBAC
```

## Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Network Perimeter                                       │
│  - Ingress Controller with WAF                                   │
│  - TLS termination with cert-manager                            │
│  - DDoS protection                                               │
├─────────────────────────────────────────────────────────────────┤
│ Layer 2: Cluster Security                                        │
│  - RBAC with least privilege                                     │
│  - Pod Security Admission (Restricted)                          │
│  - NetworkPolicies (default deny)                               │
├─────────────────────────────────────────────────────────────────┤
│ Layer 3: Admission Control                                       │
│  - Kyverno policy enforcement                                    │
│  - Image signature verification                                  │
│  - Resource validation                                           │
├─────────────────────────────────────────────────────────────────┤
│ Layer 4: Runtime Security                                        │
│  - Container isolation                                           │
│  - Read-only root filesystem                                     │
│  - Dropped capabilities                                          │
├─────────────────────────────────────────────────────────────────┤
│ Layer 5: Workload Security                                       │
│  - Non-root containers                                           │
│  - Resource limits                                               │
│  - Health probes                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Security Policies Enforced

1. **No privileged containers** - Enforced
2. **No root containers** - Enforced
3. **No privilege escalation** - Enforced
4. **No host namespaces** - Enforced
5. **No host ports** - Enforced
6. **No hostPath volumes** - Enforced
7. **Approved registries only** - Enforced
8. **No :latest tags** - Enforced
9. **Resource limits required** - Enforced
10. **Read-only root filesystem** - Audit (recommended)

## Getting Started

### Prerequisites

- Kubernetes cluster v1.25+
- Helm v3.10+
- kubectl configured with cluster admin access
- Git repository for GitOps

### Platform Installation

```bash
# 1. Clone the repository
git clone https://github.com/org/multi-tenant-platform.git
cd multi-tenant-platform

# 2. Install platform prerequisites
./scripts/install-prerequisites.sh

# 3. Install Capsule (optional)
helm install capsule capsule/capsule -n capsule-system --create-namespace

# 4. Install ArgoCD
helm install argocd argo/argo-cd -n argocd --create-namespace \
  -f gitops/argocd/argocd-values.yaml

# 5. Install Kyverno
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# 6. Apply platform policies
kubectl apply -f policies/kyverno/

# 7. Install observability stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n observability --create-namespace \
  -f observability/prometheus/prometheus-values.yaml

# 8. Verify installation
kubectl get pods -A | grep -E "(argocd|kyverno|prometheus|loki)"
```

### Onboarding a New Tenant

```bash
# Basic onboarding
./scripts/onboard-tenant.sh \
  --name acme \
  --tier starter \
  --owner-email admin@acme.com

# Full options
./scripts/onboard-tenant.sh \
  --name acme \
  --tier professional \
  --owner-email admin@acme.com \
  --owner-team platform-team \
  --cost-center CC-1234 \
  --environments dev,staging,prod \
  --git-repo https://github.com/acme/k8s-apps \
  --git-branch main

# Dry run to preview
./scripts/onboard-tenant.sh \
  --name test \
  --tier free \
  --owner-email test@example.com \
  --dry-run
```

## Platform Operations

### Monitoring Platform Health

```bash
# Check all platform components
kubectl get pods -n platform-system
kubectl get pods -n argocd
kubectl get pods -n kyverno
kubectl get pods -n observability

# View platform metrics
kubectl port-forward -n observability svc/prometheus-prometheus 9090:9090

# View platform logs
kubectl logs -n observability -l app.kubernetes.io/name=loki -f
```

### Managing Tenants

```bash
# List all tenants
kubectl get namespaces -l platform.devsecops.io/tenant

# View tenant resource usage
kubectl describe resourcequota -n acme-dev

# View tenant network policies
kubectl get networkpolicies -n acme-dev

# Suspend a tenant
kubectl label namespace acme-dev platform.devsecops.io/status=suspended

# Offboard a tenant
./scripts/offboard-tenant.sh --name acme
```

## Tenant Operations

### Deploying Applications

Tenants deploy applications via GitOps using ArgoCD:

```yaml
# apps/my-app/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    platform.devsecops.io/tenant: acme
    platform.devsecops.io/app: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
        platform.devsecops.io/tenant: acme
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: my-app
          image: ghcr.io/acme/my-app:v1.2.3
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
```

### Accessing Logs and Metrics

Tenants can access their scoped views via Grafana:

1. Navigate to `https://grafana.platform.example.com`
2. Log in with your SSO credentials
3. Select your tenant from the dropdown
4. View the "Tenant Overview" dashboard

### Self-Service Operations

```bash
# View your namespaces
kubectl get namespaces -l platform.devsecops.io/tenant=acme

# Check resource usage
kubectl top pods -n acme-dev

# View application logs
kubectl logs -n acme-dev -l app=my-app -f

# Scale deployment
kubectl scale deployment my-app -n acme-dev --replicas=3

# Trigger ArgoCD sync
argocd app sync acme-my-app
```

## Observability

### Metrics

Prometheus collects metrics from all tenant workloads with automatic tenant labeling:

- `container_cpu_usage_seconds_total{tenant="acme"}`
- `container_memory_working_set_bytes{tenant="acme"}`
- `kube_pod_status_phase{tenant="acme"}`

### Logging

Loki ingests logs with tenant isolation:

```logql
{namespace=~"acme-.*"} |= "error"
{namespace="acme-prod", container="my-app"} | json | level="error"
```

### Alerting

Alerts are automatically routed based on tenant:

1. **Tenant alerts** → Tenant's configured channels (Slack, email, PagerDuty)
2. **Critical alerts** → Platform team + Tenant
3. **Security alerts** → Security team + Platform team

## Policy Enforcement

### Viewing Policy Reports

```bash
# View policy violations for a namespace
kubectl get policyreport -n acme-dev

# View cluster-wide policy status
kubectl get clusterpolicyreport

# Check specific policy
kubectl describe cpol disallow-privileged-containers
```

### Common Policy Violations

| Violation | Resolution |
|-----------|------------|
| Privileged container | Set `securityContext.privileged: false` |
| Running as root | Set `securityContext.runAsNonRoot: true` |
| No resource limits | Add `resources.limits` |
| Latest tag | Use specific image tag |
| Unapproved registry | Use approved registry |

## CI/CD Integration

### GitHub Actions Pipeline

Use the provided pipeline template for secure builds:

```yaml
# .github/workflows/deploy.yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: platform/workflows/.github/workflows/tenant-pipeline.yaml@main
    with:
      tenant: acme
      environment: dev
    secrets:
      REGISTRY_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

### Security Gates

Every deployment must pass:

1. **Vulnerability scanning** - No critical/high CVEs
2. **Secret detection** - No exposed credentials
3. **Policy validation** - Passes Kyverno policies
4. **Image signing** - Signed by trusted key

## Troubleshooting

### Common Issues

**Pod not starting**
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

**Network connectivity issues**
```bash
kubectl get networkpolicies -n <namespace>
kubectl describe networkpolicy -n <namespace>
```

**Resource quota exceeded**
```bash
kubectl describe resourcequota -n <namespace>
kubectl top pods -n <namespace>
```

**Policy violation**
```bash
kubectl get policyreport -n <namespace> -o yaml
kubectl describe cpol <policy-name>
```

### Getting Help

- **Platform documentation**: `/docs/`
- **Issue tracker**: `https://github.com/org/platform/issues`
- **Slack channel**: `#platform-support`
- **On-call**: PagerDuty rotation for critical issues

---

## License

This project is licensed under the Apache License 2.0.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
