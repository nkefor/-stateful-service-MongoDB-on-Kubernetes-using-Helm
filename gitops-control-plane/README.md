# Multi-Cluster GitOps Control Plane with Secure Fleet Management

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Crossplane](https://img.shields.io/badge/Crossplane-1.14+-purple)](https://crossplane.io/)
[![Flux](https://img.shields.io/badge/Flux-2.x-5468FF?logo=flux)](https://fluxcd.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-2.9+-orange?logo=argo)](https://argoproj.github.io/cd/)

> **Enterprise-grade GitOps platform for managing multi-cluster Kubernetes environments with declarative infrastructure, policy enforcement, and secure fleet management.**

---

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Directory Structure](#directory-structure)
- [Getting Started](#getting-started)
- [Core Components](#core-components)
- [Real-World Use Cases](#real-world-use-cases)
- [Security Model](#security-model)
- [Operational Runbooks](#operational-runbooks)
- [Contributing](#contributing)

---

## Overview

This project implements a **hub-and-spoke GitOps control plane** that enables organizations to:

- **Provision clusters** (EKS/GKE/AKS) declaratively using Crossplane
- **Bootstrap each cluster** with a standardized platform stack
- **Deploy applications** across the fleet with environment and region-specific variations
- **Enforce global policies** and compliance requirements centrally
- **Manage configuration drift** through continuous reconciliation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GITOPS CONTROL PLANE                                │
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   GitHub    │    │  Platform   │    │    App      │    │   Policy    │  │
│  │    Repos    │───▶│   Config    │───▶│   Config    │───▶│   Bundles   │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    MANAGEMENT CLUSTER (Hub)                          │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────────────┐ │   │
│  │  │ Crossplane│  │   Flux    │  │  ArgoCD   │  │ Policy Controller │ │   │
│  │  │           │  │ (Fleet)   │  │  (Apps)   │  │  (OPA/Kyverno)    │ │   │
│  │  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────────┬─────────┘ │   │
│  └────────┼──────────────┼──────────────┼──────────────────┼───────────┘   │
│           │              │              │                  │               │
└───────────┼──────────────┼──────────────┼──────────────────┼───────────────┘
            │              │              │                  │
            ▼              ▼              ▼                  ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                        WORKLOAD CLUSTERS (Spokes)                          │
│                                                                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │  DEV Cluster     │  │ STAGING Cluster  │  │  PROD Cluster    │         │
│  │  (us-east-1)     │  │  (us-east-1)     │  │  (us-east-1)     │         │
│  │                  │  │                  │  │                  │         │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │         │
│  │ │ Flux Agent   │ │  │ │ Flux Agent   │ │  │ │ Flux Agent   │ │         │
│  │ │ ArgoCD Agent │ │  │ │ ArgoCD Agent │ │  │ │ ArgoCD Agent │ │         │
│  │ │ Kyverno      │ │  │ │ Kyverno      │ │  │ │ Kyverno      │ │         │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │  DEV Cluster     │  │ STAGING Cluster  │  │  PROD Cluster    │         │
│  │  (eu-west-1)     │  │  (eu-west-1)     │  │  (eu-west-1)     │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## Problem Statement

### The Multi-Cluster Challenge

Once organizations scale beyond a single Kubernetes cluster, they face critical challenges:

| Challenge | Impact | Without GitOps |
|-----------|--------|----------------|
| **Configuration Drift** | Environments become inconsistent over time | Manual audits, firefighting |
| **Promotion Complexity** | Moving changes between dev/stage/prod | Error-prone manual processes |
| **Compliance Gaps** | Security policies inconsistently applied | Audit failures, vulnerabilities |
| **Blast Radius** | Single change affects entire fleet | Cascading outages |
| **Visibility** | "Who changed what in prod?" | Blame games, no audit trail |

### The Solution: GitOps Fleet Management

This control plane provides:

- **Single Source of Truth**: Git repositories define all cluster states
- **Declarative Everything**: Infrastructure, apps, and policies as code
- **Automated Reconciliation**: Continuous drift detection and correction
- **Progressive Delivery**: Safe promotion workflows with gates
- **Centralized Governance**: Policies enforced at scale

---

## Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              EXTERNAL SERVICES                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │   GitHub    │  │    Vault    │  │  Container  │  │   Slack/    │                 │
│  │  (Git Ops)  │  │  (Secrets)  │  │  Registry   │  │   PagerDuty │                 │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                 │
└─────────┼────────────────┼────────────────┼────────────────┼────────────────────────┘
          │                │                │                │
          ▼                ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           MANAGEMENT CLUSTER (Hub)                                   │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                         CONTROL PLANE LAYER                                     │ │
│  │                                                                                 │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │ │
│  │  │   CROSSPLANE    │  │   FLUX FLEET    │  │  ARGOCD APPS    │                 │ │
│  │  │                 │  │   CONTROLLER    │  │  CONTROLLER     │                 │ │
│  │  │ • AWS Provider  │  │                 │  │                 │                 │ │
│  │  │ • GCP Provider  │  │ • Source Ctrl   │  │ • App Projects  │                 │ │
│  │  │ • Azure Provider│  │ • Kustomize Ctrl│  │ • AppSets       │                 │ │
│  │  │                 │  │ • Helm Ctrl     │  │ • Sync Policies │                 │ │
│  │  │ Compositions:   │  │ • Notification  │  │                 │                 │ │
│  │  │ • EKS Cluster   │  │   Controller    │  │ Cluster Secrets │                 │ │
│  │  │ • GKE Cluster   │  │                 │  │ (from Crossplane)│                 │ │
│  │  │ • AKS Cluster   │  │ GitRepos:       │  │                 │                 │ │
│  │  │ • VPC Networks  │  │ • Platform      │  │                 │                 │ │
│  │  │ • Databases     │  │ • Apps          │  │                 │                 │ │
│  │  │                 │  │ • Policies      │  │                 │                 │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │ │
│  │                                                                                 │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │ │
│  │  │ POLICY ENGINE   │  │  SECRETS MGMT   │  │  OBSERVABILITY  │                 │ │
│  │  │                 │  │                 │  │                 │                 │ │
│  │  │ • Kyverno       │  │ • External      │  │ • Prometheus    │                 │ │
│  │  │ • OPA Gatekeeper│  │   Secrets       │  │ • Grafana       │                 │ │
│  │  │ • Policy Bundles│  │   Operator      │  │ • Loki          │                 │ │
│  │  │                 │  │ • Vault Agent   │  │ • Alertmanager  │                 │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
└──────────────────────────────────────┬──────────────────────────────────────────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
┌─────────────────────────┐  ┌─────────────────────────┐  ┌─────────────────────────┐
│   DEVELOPMENT FLEET     │  │    STAGING FLEET        │  │   PRODUCTION FLEET      │
│                         │  │                         │  │                         │
│ ┌─────────────────────┐ │  │ ┌─────────────────────┐ │  │ ┌─────────────────────┐ │
│ │  us-east-1 (EKS)    │ │  │ │  us-east-1 (EKS)    │ │  │ │  us-east-1 (EKS)    │ │
│ │  ┌───────────────┐  │ │  │ │  ┌───────────────┐  │ │  │ │  ┌───────────────┐  │ │
│ │  │ Flux Agent    │  │ │  │ │  │ Flux Agent    │  │ │  │ │  │ Flux Agent    │  │ │
│ │  │ Kyverno Agent │  │ │  │ │  │ Kyverno Agent │  │ │  │ │  │ Kyverno Agent │  │ │
│ │  │ Platform Stack│  │ │  │ │  │ Platform Stack│  │ │  │ │  │ Platform Stack│  │ │
│ │  │ App Workloads │  │ │  │ │  │ App Workloads │  │ │  │ │  │ App Workloads │  │ │
│ │  └───────────────┘  │ │  │ │  └───────────────┘  │ │  │ │  └───────────────┘  │ │
│ └─────────────────────┘ │  │ └─────────────────────┘ │  │ └─────────────────────┘ │
│                         │  │                         │  │                         │
│ ┌─────────────────────┐ │  │ ┌─────────────────────┐ │  │ ┌─────────────────────┐ │
│ │  eu-west-1 (EKS)    │ │  │ │  eu-west-1 (EKS)    │ │  │ │  eu-west-1 (EKS)    │ │
│ │  ┌───────────────┐  │ │  │ │  ┌───────────────┐  │ │  │ │  ┌───────────────┐  │ │
│ │  │ Flux Agent    │  │ │  │ │  │ Flux Agent    │  │ │  │ │  │ Flux Agent    │  │ │
│ │  │ Kyverno Agent │  │ │  │ │  │ Kyverno Agent │  │ │  │ │  │ Kyverno Agent │  │ │
│ │  │ Platform Stack│  │ │  │ │  │ Platform Stack│  │ │  │ │  │ Platform Stack│  │ │
│ │  │ App Workloads │  │ │  │ │  │ App Workloads │  │ │  │ │  │ App Workloads │  │ │
│ │  └───────────────┘  │ │  │ │  └───────────────┘  │ │  │ │  └───────────────┘  │ │
│ └─────────────────────┘ │  │ └─────────────────────┘ │  │ └─────────────────────┘ │
│                         │  │                         │  │                         │
│ ┌─────────────────────┐ │  │ ┌─────────────────────┐ │  │ ┌─────────────────────┐ │
│ │  ap-south-1 (GKE)   │ │  │ │  ap-south-1 (GKE)   │ │  │ │  ap-south-1 (GKE)   │ │
│ └─────────────────────┘ │  │ └─────────────────────┘ │  │ └─────────────────────┘ │
└─────────────────────────┘  └─────────────────────────┘  └─────────────────────────┘
```

### GitOps Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                              GITOPS PROMOTION WORKFLOW                               │
└──────────────────────────────────────────────────────────────────────────────────────┘

     Developer                    Platform Team                    SRE Team
         │                             │                              │
         │  1. Push App Changes        │                              │
         ▼                             │                              │
    ┌─────────┐                        │                              │
    │  App    │                        │                              │
    │  Repo   │                        │                              │
    │ (dev)   │                        │                              │
    └────┬────┘                        │                              │
         │                             │                              │
         │  2. Automated Tests         │                              │
         ▼                             │                              │
    ┌─────────┐                        │                              │
    │   CI    │                        │                              │
    │Pipeline │                        │                              │
    └────┬────┘                        │                              │
         │                             │                              │
         │  3. Auto-merge to dev       │                              │
         ▼                             │                              │
    ┌─────────┐                        │                              │
    │  Flux   │──────── Sync ─────────▶│  4. Deploy to Dev Cluster   │
    │  (dev)  │                        │                              │
    └────┬────┘                        │                              │
         │                             │                              │
         │  5. Create PR: dev → staging│                              │
         ▼                             │                              │
    ┌─────────────┐                    │                              │
    │  Promotion  │                    │                              │
    │     PR      │◀── 6. Review & ────┤                              │
    │             │      Approve       │                              │
    └──────┬──────┘                    │                              │
           │                           │                              │
           │  7. Merge triggers Flux   │                              │
           ▼                           │                              │
    ┌─────────┐                        │                              │
    │  Flux   │──────── Sync ─────────▶│  8. Deploy to Staging        │
    │(staging)│                        │                              │
    └────┬────┘                        │                              │
         │                             │                              │
         │  9. Smoke Tests Pass        │                              │
         │                             │                              │
         │  10. Create PR: staging → prod                             │
         ▼                                                            │
    ┌─────────────┐                                                   │
    │  Promotion  │◀───────── 11. Review & Approve ───────────────────┤
    │     PR      │                                                   │
    └──────┬──────┘                                                   │
           │                                                          │
           │  12. Canary Rollout (10% → 50% → 100%)                  │
           ▼                                                          │
    ┌─────────┐                                                       │
    │  Flux   │──────── Phased Sync ─────────────────────────────────▶│
    │ (prod)  │                                                       │
    └─────────┘                                                       │
                                                                      │
                         13. Automated Rollback if metrics degrade ───┘
```

### Cluster Provisioning Flow

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                         CROSSPLANE CLUSTER PROVISIONING                              │
└──────────────────────────────────────────────────────────────────────────────────────┘

    ┌────────────────┐
    │ Infrastructure │
    │   Git Repo     │
    │                │
    │ clusters/      │
    │ ├── dev/       │
    │ │   └── claim  │◄──── 1. Engineer commits cluster claim
    │ ├── staging/   │
    │ └── prod/      │
    └───────┬────────┘
            │
            │ 2. Flux detects change
            ▼
    ┌────────────────┐
    │  Management    │
    │   Cluster      │
    │                │
    │ ┌────────────┐ │
    │ │ Crossplane │ │◄──── 3. Crossplane reconciles claim
    │ └─────┬──────┘ │
    │       │        │
    │       ▼        │
    │ ┌────────────┐ │
    │ │   AWS/GCP  │ │       4. Create cloud resources:
    │ │  Provider  │─┼─────────▶ • VPC & Subnets
    │ └────────────┘ │          • IAM Roles (IRSA)
    │                │          • EKS Cluster
    └────────┬───────┘          • Node Groups
             │                  • Security Groups
             │
             │ 5. Cluster created
             ▼
    ┌────────────────┐
    │  New Workload  │
    │    Cluster     │
    │                │
    │ ┌────────────┐ │
    │ │ Bootstrap  │ │◄──── 6. Auto-bootstrap:
    │ │ Job runs   │ │         • Install Flux
    │ └────────────┘ │         • Apply platform configs
    │                │         • Deploy base policies
    │ ┌────────────┐ │
    │ │ Flux Agent │ │◄──── 7. Cluster now self-managing
    │ │ installed  │ │         via GitOps
    │ └────────────┘ │
    │                │
    │ ┌────────────┐ │
    │ │ Kyverno    │ │◄──── 8. Policies enforced
    │ │ installed  │ │
    │ └────────────┘ │
    └────────────────┘
```

---

## Key Features

### 1. Declarative Fleet Provisioning

```yaml
# Example: Provision a production EKS cluster
apiVersion: platform.gitops.io/v1alpha1
kind: ClusterClaim
metadata:
  name: prod-us-east-1
  namespace: fleet-system
spec:
  cloudProvider: aws
  region: us-east-1
  environment: production
  kubernetes:
    version: "1.28"
  nodeGroups:
    - name: system
      instanceType: m6i.xlarge
      minSize: 3
      maxSize: 10
    - name: applications
      instanceType: m6i.2xlarge
      minSize: 5
      maxSize: 50
      taints:
        - key: workload
          value: apps
          effect: NoSchedule
  addons:
    - aws-ebs-csi-driver
    - aws-load-balancer-controller
    - cluster-autoscaler
```

### 2. Multi-Tenant Application Deployment

```yaml
# ApplicationSet for fleet-wide deployment
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: payment-service
spec:
  generators:
    - matrix:
        generators:
          - clusters:
              selector:
                matchLabels:
                  environment: production
          - list:
              elements:
                - region: us-east-1
                - region: eu-west-1
  template:
    spec:
      source:
        repoURL: https://github.com/org/payment-service
        path: deploy/{{environment}}/{{region}}
      destination:
        server: '{{server}}'
        namespace: payments
```

### 3. Centralized Policy Enforcement

```yaml
# Kyverno ClusterPolicy - Applied to all clusters
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: enforce
  rules:
    - name: require-limits
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "CPU and memory limits are required"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```

### 4. Progressive Rollout Strategies

```yaml
# Flagger Canary for production deployments
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: payment-service
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payment-service
  progressDeadlineSeconds: 60
  service:
    port: 80
  analysis:
    interval: 30s
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
      - name: request-success-rate
        threshold: 99
      - name: request-duration
        threshold: 500
```

---

## Directory Structure

```
gitops-control-plane/
├── README.md                          # This file
├── ARCHITECTURE.md                    # Detailed architecture documentation
├── USE_CASES.md                       # Real-world use cases
│
├── management-cluster/                # Hub cluster configurations
│   ├── crossplane/                    # Infrastructure as Code
│   │   ├── providers/                 # Cloud provider configs
│   │   ├── compositions/              # Reusable infra templates
│   │   ├── claims/                    # Cluster definitions
│   │   └── xrds/                      # Custom Resource Definitions
│   ├── bootstrap/                     # Cluster bootstrap scripts
│   └── monitoring/                    # Observability stack
│
├── workload-clusters/                 # Per-cluster configurations
│   ├── dev/
│   │   ├── us-east-1/
│   │   └── eu-west-1/
│   ├── staging/
│   │   ├── us-east-1/
│   │   └── eu-west-1/
│   └── prod/
│       ├── us-east-1/
│       └── eu-west-1/
│
├── gitops/                            # GitOps controllers config
│   ├── flux/                          # Flux CD configurations
│   │   ├── clusters/                  # Per-cluster Flux configs
│   │   ├── infrastructure/            # Platform components
│   │   └── apps/                      # Application configs
│   └── argocd/                        # Argo CD configurations
│       ├── applications/              # App definitions
│       ├── applicationsets/           # Fleet-wide apps
│       └── projects/                  # RBAC boundaries
│
├── policies/                          # Security & compliance
│   ├── kyverno/                       # Kyverno policies
│   ├── opa-gatekeeper/                # OPA constraints
│   └── admission-controllers/         # Webhook configs
│
├── terraform/                         # Legacy/bootstrap infra
│   ├── modules/                       # Reusable modules
│   │   ├── eks/
│   │   ├── gke/
│   │   ├── aks/
│   │   ├── vpc/
│   │   └── iam/
│   └── environments/                  # Per-env configs
│
├── helm-charts/                       # Platform Helm charts
│   ├── platform-stack/                # Core platform components
│   ├── observability-stack/           # Monitoring & logging
│   ├── security-stack/                # Security tools
│   └── ingress-stack/                 # Ingress controllers
│
├── docs/                              # Documentation
│   ├── architecture/                  # Design docs
│   ├── runbooks/                      # Operational guides
│   └── tutorials/                     # Getting started guides
│
├── scripts/                           # Utility scripts
│   ├── bootstrap/                     # Initial setup
│   ├── validation/                    # Pre-commit checks
│   └── migration/                     # Migration helpers
│
└── ci-cd/                             # CI/CD pipelines
    ├── github-actions/                # GitHub workflows
    └── tekton/                        # Tekton pipelines
```

---

## Getting Started

### Prerequisites

- **kubectl** >= 1.28
- **helm** >= 3.12
- **flux** >= 2.1
- **crossplane** CLI
- **AWS/GCP/Azure** CLI (based on your cloud)
- **GitHub** access with repository permissions

### Quick Start

#### 1. Bootstrap Management Cluster

```bash
# Clone this repository
git clone https://github.com/your-org/gitops-control-plane.git
cd gitops-control-plane

# Create management cluster (using eksctl for AWS example)
eksctl create cluster -f management-cluster/bootstrap/eksctl-config.yaml

# Install Crossplane
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace

# Install Crossplane providers
kubectl apply -f management-cluster/crossplane/providers/

# Install Flux
flux bootstrap github \
  --owner=your-org \
  --repository=gitops-control-plane \
  --path=gitops/flux/clusters/management \
  --personal
```

#### 2. Provision First Workload Cluster

```bash
# Apply cluster claim (Crossplane will create the cluster)
kubectl apply -f management-cluster/crossplane/claims/dev-us-east-1.yaml

# Watch cluster creation
kubectl get clusters.eks.aws.crossplane.io -w

# Once ready, bootstrap Flux on the new cluster
./scripts/bootstrap/bootstrap-cluster.sh dev-us-east-1
```

#### 3. Deploy Your First Application

```bash
# Create application namespace
kubectl create namespace my-app

# Apply Flux Kustomization
kubectl apply -f - <<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/my-app
  prune: true
  sourceRef:
    kind: GitRepository
    name: apps-repo
EOF
```

---

## Core Components

### Management Cluster Components

| Component | Purpose | Version |
|-----------|---------|---------|
| Crossplane | Infrastructure provisioning | 1.14+ |
| AWS/GCP/Azure Provider | Cloud resource management | Latest |
| Flux CD | GitOps synchronization | 2.1+ |
| Argo CD | Application delivery | 2.9+ |
| Kyverno | Policy enforcement | 1.11+ |
| External Secrets Operator | Secrets management | 0.9+ |
| Prometheus Stack | Monitoring | 51+ |
| Loki Stack | Log aggregation | 2.9+ |

### Workload Cluster Components (Auto-deployed)

| Component | Purpose |
|-----------|---------|
| Flux Agent | Local GitOps reconciliation |
| Kyverno Agent | Policy enforcement |
| Cert-Manager | TLS certificate management |
| External-DNS | DNS record management |
| AWS LB Controller / Nginx | Ingress management |
| Metrics Server | Resource metrics |
| Cluster Autoscaler | Node scaling |

---

## Real-World Use Cases

See [USE_CASES.md](./USE_CASES.md) for detailed scenarios including:

1. **Multi-Region E-Commerce Platform** - Global deployment with regional failover
2. **Financial Services Compliance** - PCI-DSS compliant multi-cluster setup
3. **SaaS Multi-Tenant Isolation** - Per-customer cluster provisioning
4. **Blue-Green Cluster Upgrades** - Zero-downtime Kubernetes upgrades
5. **Disaster Recovery** - Cross-region failover automation

---

## Security Model

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                               │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: Git Repository Security                               │
│  • Branch protection rules                                      │
│  • Required PR reviews                                          │
│  • Signed commits                                               │
│  • CODEOWNERS enforcement                                       │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: CI/CD Pipeline Security                               │
│  • Policy-as-Code validation (conftest)                         │
│  • Image scanning (Trivy)                                       │
│  • Secret detection (gitleaks)                                  │
│  • SBOM generation                                              │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: Admission Control                                     │
│  • Kyverno policy enforcement                                   │
│  • OPA Gatekeeper constraints                                   │
│  • Image signature verification                                 │
│  • Resource quota enforcement                                   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4: Runtime Security                                      │
│  • Network policies                                             │
│  • Pod Security Standards                                       │
│  • Falco runtime detection                                      │
│  • Service mesh mTLS                                            │
├─────────────────────────────────────────────────────────────────┤
│  Layer 5: Secrets Management                                    │
│  • External Secrets Operator                                    │
│  • Vault integration                                            │
│  • AWS Secrets Manager                                          │
│  • Encryption at rest                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Role Separation

| Team | Repository Access | Cluster Access |
|------|-------------------|----------------|
| **App Developers** | apps-repo (dev branch) | Dev namespace only |
| **Platform Team** | platform-config, infra-repo | All clusters, system namespaces |
| **SRE Team** | All repos (reviewer) | All clusters (full access) |
| **Security Team** | policies-repo | Policy namespaces |

---

## Operational Runbooks

### Common Operations

| Operation | Command/Process |
|-----------|-----------------|
| Scale cluster nodes | Edit cluster claim in Git |
| Upgrade Kubernetes | Update version in claim, Crossplane handles rollout |
| Deploy new app | PR to apps-repo, merge triggers deployment |
| Rollback deployment | `flux reconcile` or Git revert |
| Check drift status | `flux get all -A` |
| Force reconciliation | `flux reconcile source git flux-system` |

### Incident Response

See [docs/runbooks/](./docs/runbooks/) for detailed procedures on:
- Cluster recovery
- Policy violation investigation
- Secret rotation
- Network isolation
- Rollback procedures

---

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Review Requirements

- All changes must be reviewed by at least one Platform Team member
- Policy changes require Security Team approval
- Production changes require SRE approval

---

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [AWS Prescriptive Guidance - GitOps](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/use-gitops-for-kubernetes-deployments.html)
- [Flux CD Documentation](https://fluxcd.io/docs/)
- [Crossplane Documentation](https://crossplane.io/docs/)
- [Argo CD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
