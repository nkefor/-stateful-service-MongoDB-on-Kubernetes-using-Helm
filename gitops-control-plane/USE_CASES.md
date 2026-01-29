# Real-World Use Cases

This document details practical, production-tested scenarios for the Multi-Cluster GitOps Control Plane.

---

## Table of Contents

1. [Multi-Region E-Commerce Platform](#1-multi-region-e-commerce-platform)
2. [Financial Services Compliance](#2-financial-services-compliance)
3. [SaaS Multi-Tenant Isolation](#3-saas-multi-tenant-isolation)
4. [Blue-Green Cluster Upgrades](#4-blue-green-cluster-upgrades)
5. [Disaster Recovery Automation](#5-disaster-recovery-automation)
6. [Regulated Healthcare Platform](#6-regulated-healthcare-platform)
7. [Edge Computing Fleet](#7-edge-computing-fleet)
8. [Development Environments On-Demand](#8-development-environments-on-demand)

---

## 1. Multi-Region E-Commerce Platform

### Business Context

A global e-commerce company needs to deploy their platform across multiple regions to:
- Reduce latency for customers worldwide
- Comply with data residency requirements (GDPR, etc.)
- Provide high availability with regional failover
- Handle traffic spikes during sales events

### Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                        GLOBAL E-COMMERCE PLATFORM                              │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│    Route 53 / CloudFlare (Global Load Balancing)                               │
│    ┌────────────────────────────────────────────────────────────────────────┐  │
│    │                      Latency-based routing                              │  │
│    │                      Health check failover                              │  │
│    └─────────────┬────────────────┬────────────────┬───────────────────────┘  │
│                  │                │                │                          │
│                  ▼                ▼                ▼                          │
│    ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│    │   US-EAST-1     │  │   EU-WEST-1     │  │  AP-SOUTHEAST-1 │              │
│    │   (Primary)     │  │   (GDPR Zone)   │  │   (APAC)        │              │
│    │                 │  │                 │  │                 │              │
│    │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │              │
│    │ │ Frontend    │ │  │ │ Frontend    │ │  │ │ Frontend    │ │              │
│    │ │ Cart Service│ │  │ │ Cart Service│ │  │ │ Cart Service│ │              │
│    │ │ Order Svc   │ │  │ │ Order Svc   │ │  │ │ Order Svc   │ │              │
│    │ │ Payment Svc │ │  │ │ Payment Svc │ │  │ │ Payment Svc │ │              │
│    │ │ Inventory   │ │  │ │ Inventory   │ │  │ │ Inventory   │ │              │
│    │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │              │
│    │                 │  │                 │  │                 │              │
│    │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │              │
│    │ │ Aurora      │ │  │ │ Aurora      │ │  │ │ Aurora      │ │              │
│    │ │ Global DB   │◄┼──┼─┤ Read Replica│ │  │ │ Read Replica│ │              │
│    │ │ (Primary)   │ │  │ │             │ │  │ │             │ │              │
│    │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │              │
│    └─────────────────┘  └─────────────────┘  └─────────────────┘              │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
```

### GitOps Implementation

```yaml
# clusters/prod/e-commerce-us-east-1.yaml
apiVersion: platform.gitops.io/v1alpha1
kind: ClusterClaim
metadata:
  name: ecommerce-prod-us-east-1
  labels:
    environment: production
    region: us-east-1
    tier: primary
    compliance: pci-dss
spec:
  cloudProvider: aws
  region: us-east-1
  kubernetes:
    version: "1.28"
  nodeGroups:
    - name: frontend
      instanceType: c6i.2xlarge
      minSize: 10
      maxSize: 100
      labels:
        workload: frontend
    - name: backend
      instanceType: m6i.4xlarge
      minSize: 20
      maxSize: 200
      labels:
        workload: backend
    - name: database
      instanceType: r6i.2xlarge
      minSize: 6
      maxSize: 12
      labels:
        workload: stateful
      taints:
        - key: dedicated
          value: database
          effect: NoSchedule
  networking:
    vpcCidr: "10.10.0.0/16"
    podCidr: "10.20.0.0/16"
    serviceCidr: "10.30.0.0/16"
  addons:
    - aws-ebs-csi-driver
    - aws-load-balancer-controller
    - cluster-autoscaler
    - metrics-server
```

### Region-Specific Configuration

```yaml
# apps/e-commerce/overlays/eu-west-1/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: e-commerce
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: user-service
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: GDPR_MODE
          value: "true"
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: DATA_RESIDENCY_REGION
          value: "eu-west-1"
  - target:
      kind: ConfigMap
      name: app-config
    patch: |-
      - op: replace
        path: /data/COOKIE_CONSENT_REQUIRED
        value: "true"
```

### Traffic Management During Sales Events

```yaml
# Flagger configuration for Black Friday scaling
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: frontend
  namespace: e-commerce
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend
  autoscalerRef:
    apiVersion: autoscaling/v2
    kind: HorizontalPodAutoscaler
    name: frontend
  service:
    port: 80
    targetPort: 8080
    gateways:
      - public-gateway.istio-system.svc.cluster.local
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 100
    stepWeight: 20
    metrics:
      - name: request-success-rate
        thresholdRange:
          min: 99
      - name: request-duration
        thresholdRange:
          max: 500
      - name: custom-pod-cpu
        thresholdRange:
          max: 80
        templateRef:
          name: cpu-usage
```

### Benefits Achieved

| Metric | Before GitOps | After GitOps |
|--------|---------------|--------------|
| Deployment time | 4 hours | 15 minutes |
| Configuration drift incidents | 12/month | 0 |
| Regional failover time | 30 minutes | 3 minutes |
| Compliance audit time | 2 weeks | 2 days |

---

## 2. Financial Services Compliance

### Business Context

A financial services company must maintain PCI-DSS compliance across all environments while enabling rapid development and deployment of banking applications.

### Compliance Requirements

- All containers must be signed and scanned
- Network policies must enforce zero-trust
- All secrets must be managed through Vault
- Complete audit trail for all changes
- Encryption at rest and in transit
- Regular compliance reporting

### Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                    PCI-DSS COMPLIANT BANKING PLATFORM                          │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                     CARDHOLDER DATA ENVIRONMENT (CDE)                     │  │
│  │                                                                           │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐           │  │
│  │  │  Payment        │  │  Card           │  │  Transaction    │           │  │
│  │  │  Gateway        │  │  Tokenization   │  │  Processor      │           │  │
│  │  │  (PCI Zone A)   │  │  (PCI Zone B)   │  │  (PCI Zone C)   │           │  │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘           │  │
│  │           │                    │                    │                     │  │
│  │           └────────────────────┼────────────────────┘                     │  │
│  │                                │                                          │  │
│  │                    ┌───────────┴───────────┐                              │  │
│  │                    │   Internal Network    │                              │  │
│  │                    │   (Encrypted mTLS)    │                              │  │
│  │                    └───────────┬───────────┘                              │  │
│  └────────────────────────────────┼──────────────────────────────────────────┘  │
│                                   │                                            │
│  ┌────────────────────────────────┼──────────────────────────────────────────┐  │
│  │                         NON-CDE SERVICES                                   │  │
│  │                                │                                           │  │
│  │  ┌─────────────────┐  ┌───────┴───────┐  ┌─────────────────┐              │  │
│  │  │  Account        │  │  API          │  │  Notification   │              │  │
│  │  │  Management     │  │  Gateway      │  │  Service        │              │  │
│  │  └─────────────────┘  └───────────────┘  └─────────────────┘              │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                                                                                │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                        SECURITY CONTROLS                                   │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ Vault        │  │ Falco        │  │ Network      │  │ Image        │   │  │
│  │  │ (Secrets)    │  │ (Runtime)    │  │ Policies     │  │ Scanning     │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────┘
```

### Policy Implementation

```yaml
# policies/kyverno/pci-dss/require-signed-images.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
  annotations:
    policies.kyverno.io/title: Verify Image Signatures
    policies.kyverno.io/category: PCI-DSS
    policies.kyverno.io/severity: critical
spec:
  validationFailureAction: enforce
  background: true
  rules:
    - name: verify-cosign-signature
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - payment-*
                - card-*
      verifyImages:
        - imageReferences:
            - "registry.company.com/*"
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
                      -----END PUBLIC KEY-----
```

```yaml
# policies/kyverno/pci-dss/enforce-network-policies.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-network-policy
  annotations:
    policies.kyverno.io/title: Require Network Policy
    policies.kyverno.io/category: PCI-DSS
    policies.kyverno.io/severity: high
spec:
  validationFailureAction: enforce
  rules:
    - name: check-network-policy-exists
      match:
        resources:
          kinds:
            - Deployment
          namespaceSelector:
            matchLabels:
              pci-zone: "true"
      preconditions:
        all:
          - key: "{{ request.operation }}"
            operator: In
            value: ["CREATE", "UPDATE"]
      validate:
        message: "Network policy required for all PCI zone deployments"
        deny:
          conditions:
            - key: "{{ request.object.metadata.namespace }}"
              operator: AnyNotIn
              value: "{{ networkpolicies.list('', '').items[?metadata.namespace == '{{request.object.metadata.namespace}}'].metadata.namespace }}"
```

### Audit Trail Configuration

```yaml
# gitops/flux/clusters/prod/audit-config.yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta2
kind: Alert
metadata:
  name: pci-compliance-alerts
  namespace: flux-system
spec:
  providerRef:
    name: splunk-audit
  eventSeverity: info
  eventSources:
    - kind: Kustomization
      name: '*'
      namespace: payment-system
    - kind: HelmRelease
      name: '*'
      namespace: card-services
  summary: "PCI-DSS Compliance Event"
---
apiVersion: notification.toolkit.fluxcd.io/v1beta2
kind: Provider
metadata:
  name: splunk-audit
  namespace: flux-system
spec:
  type: generic
  address: https://splunk.company.com:8088/services/collector
  secretRef:
    name: splunk-hec-token
```

### Compliance Dashboard

```yaml
# observability/grafana/dashboards/pci-compliance.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pci-compliance-dashboard
  labels:
    grafana_dashboard: "1"
data:
  pci-compliance.json: |
    {
      "title": "PCI-DSS Compliance Dashboard",
      "panels": [
        {
          "title": "Policy Violations (Last 24h)",
          "type": "stat",
          "targets": [{
            "expr": "sum(kyverno_policy_results_total{policy_result='fail'})"
          }]
        },
        {
          "title": "Image Signature Verification",
          "type": "piechart",
          "targets": [{
            "expr": "sum by (status) (cosign_verification_total)"
          }]
        },
        {
          "title": "Network Policy Coverage",
          "type": "gauge",
          "targets": [{
            "expr": "(count(kube_networkpolicy_created) / count(kube_namespace_created{namespace=~'payment.*|card.*'})) * 100"
          }]
        }
      ]
    }
```

---

## 3. SaaS Multi-Tenant Isolation

### Business Context

A B2B SaaS company provides dedicated environments for enterprise customers, requiring:
- Strong tenant isolation
- Per-tenant customization
- Automated provisioning
- Cost allocation per tenant

### Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                       MULTI-TENANT SAAS PLATFORM                               │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                     SHARED CONTROL PLANE                                  │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                    │  │
│  │  │ Tenant       │  │ Billing      │  │ Provisioning │                    │  │
│  │  │ Management   │  │ Service      │  │ Controller   │                    │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                    │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐    │
│  │                    TENANT ISOLATION STRATEGIES                          │    │
│  │                                                                         │    │
│  │  STRATEGY A: Namespace Isolation (Standard Tier)                        │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │    │
│  │  │ Shared Cluster                                                   │   │    │
│  │  │ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐        │   │    │
│  │  │ │ tenant-a  │ │ tenant-b  │ │ tenant-c  │ │ tenant-d  │        │   │    │
│  │  │ │ namespace │ │ namespace │ │ namespace │ │ namespace │        │   │    │
│  │  │ └───────────┘ └───────────┘ └───────────┘ └───────────┘        │   │    │
│  │  └─────────────────────────────────────────────────────────────────┘   │    │
│  │                                                                         │    │
│  │  STRATEGY B: Node Pool Isolation (Professional Tier)                    │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │    │
│  │  │ Shared Cluster with Dedicated Node Pools                         │   │    │
│  │  │ ┌───────────────────┐ ┌───────────────────┐                     │   │    │
│  │  │ │ tenant-e nodes    │ │ tenant-f nodes    │  (Taints/Tolerations)│   │    │
│  │  │ │ ┌───────────────┐ │ │ ┌───────────────┐ │                     │   │    │
│  │  │ │ │ tenant-e      │ │ │ │ tenant-f      │ │                     │   │    │
│  │  │ │ │ workloads     │ │ │ │ workloads     │ │                     │   │    │
│  │  │ │ └───────────────┘ │ │ └───────────────┘ │                     │   │    │
│  │  │ └───────────────────┘ └───────────────────┘                     │   │    │
│  │  └─────────────────────────────────────────────────────────────────┘   │    │
│  │                                                                         │    │
│  │  STRATEGY C: Dedicated Cluster (Enterprise Tier)                        │    │
│  │  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐        │    │
│  │  │ Tenant-G Cluster │ │ Tenant-H Cluster │ │ Tenant-I Cluster │        │    │
│  │  │ (Full Isolation) │ │ (Full Isolation) │ │ (Full Isolation) │        │    │
│  │  └──────────────────┘ └──────────────────┘ └──────────────────┘        │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────────────┘
```

### Tenant Provisioning with Crossplane

```yaml
# Composite Resource Definition for Tenant
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: tenants.platform.company.io
spec:
  group: platform.company.io
  names:
    kind: Tenant
    plural: tenants
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                tenantId:
                  type: string
                tier:
                  type: string
                  enum: ["standard", "professional", "enterprise"]
                region:
                  type: string
                resources:
                  type: object
                  properties:
                    cpuLimit:
                      type: string
                    memoryLimit:
                      type: string
                    storageLimit:
                      type: string
              required:
                - tenantId
                - tier
                - region
```

```yaml
# Composition for Enterprise Tenant (Dedicated Cluster)
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: tenant-enterprise
  labels:
    tier: enterprise
spec:
  compositeTypeRef:
    apiVersion: platform.company.io/v1alpha1
    kind: Tenant
  resources:
    # Create dedicated VPC
    - name: tenant-vpc
      base:
        apiVersion: ec2.aws.crossplane.io/v1beta1
        kind: VPC
        spec:
          forProvider:
            cidrBlock: "10.0.0.0/16"
            enableDnsHostnames: true
          providerConfigRef:
            name: aws-provider
      patches:
        - fromFieldPath: spec.tenantId
          toFieldPath: metadata.labels[tenant]

    # Create dedicated EKS cluster
    - name: tenant-cluster
      base:
        apiVersion: eks.aws.crossplane.io/v1beta1
        kind: Cluster
        spec:
          forProvider:
            version: "1.28"
            roleArnSelector:
              matchLabels:
                role: eks-cluster
          providerConfigRef:
            name: aws-provider
      patches:
        - fromFieldPath: spec.tenantId
          toFieldPath: metadata.name
          transforms:
            - type: string
              string:
                fmt: "tenant-%s-cluster"
        - fromFieldPath: spec.region
          toFieldPath: spec.forProvider.region

    # Create dedicated database
    - name: tenant-database
      base:
        apiVersion: rds.aws.crossplane.io/v1beta1
        kind: DBInstance
        spec:
          forProvider:
            dbInstanceClass: db.r6g.large
            engine: postgres
            engineVersion: "15"
            allocatedStorage: 100
          providerConfigRef:
            name: aws-provider
      patches:
        - fromFieldPath: spec.tenantId
          toFieldPath: metadata.name
          transforms:
            - type: string
              string:
                fmt: "tenant-%s-db"
```

### Automated Tenant Onboarding

```yaml
# Tenant claim (submitted by sales/provisioning system)
apiVersion: platform.company.io/v1alpha1
kind: Tenant
metadata:
  name: acme-corp
  namespace: tenant-provisioning
spec:
  tenantId: acme-corp
  tier: enterprise
  region: us-east-1
  resources:
    cpuLimit: "100"
    memoryLimit: "200Gi"
    storageLimit: "1Ti"
  customizations:
    branding:
      primaryColor: "#FF5733"
      logo: "s3://tenant-assets/acme-corp/logo.png"
    features:
      ssoEnabled: true
      customDomain: "acme.example-saas.com"
      dataRetentionDays: 365
```

---

## 4. Blue-Green Cluster Upgrades

### Business Context

Upgrading Kubernetes clusters in production without downtime requires careful orchestration. This use case demonstrates zero-downtime cluster upgrades using the blue-green pattern.

### Upgrade Process

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                    BLUE-GREEN CLUSTER UPGRADE PROCESS                          │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  PHASE 1: Preparation                                                          │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                                                                           │  │
│  │  ┌─────────────────────┐                                                  │  │
│  │  │   BLUE CLUSTER      │ ◄──── Currently serving 100% traffic             │  │
│  │  │   (K8s 1.27)        │                                                  │  │
│  │  │   ACTIVE            │                                                  │  │
│  │  └─────────────────────┘                                                  │  │
│  │                                                                           │  │
│  │  [Create Green Cluster Claim in Git]                                      │  │
│  │                                                                           │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                │
│  PHASE 2: Green Cluster Provisioning                                           │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                                                                           │  │
│  │  ┌─────────────────────┐      ┌─────────────────────┐                     │  │
│  │  │   BLUE CLUSTER      │      │   GREEN CLUSTER     │                     │  │
│  │  │   (K8s 1.27)        │      │   (K8s 1.28)        │                     │  │
│  │  │   ACTIVE            │      │   PROVISIONING      │                     │  │
│  │  │   100% traffic      │      │   0% traffic        │                     │  │
│  │  └─────────────────────┘      └─────────────────────┘                     │  │
│  │                                                                           │  │
│  │  [Crossplane creates new cluster, Flux bootstraps it]                     │  │
│  │                                                                           │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                │
│  PHASE 3: Validation                                                           │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                                                                           │  │
│  │  ┌─────────────────────┐      ┌─────────────────────┐                     │  │
│  │  │   BLUE CLUSTER      │      │   GREEN CLUSTER     │                     │  │
│  │  │   (K8s 1.27)        │      │   (K8s 1.28)        │                     │  │
│  │  │   ACTIVE            │      │   VALIDATING        │                     │  │
│  │  │   100% traffic      │      │   Smoke tests       │                     │  │
│  │  └─────────────────────┘      └─────────────────────┘                     │  │
│  │                                                                           │  │
│  │  [Run automated validation suite against green cluster]                   │  │
│  │                                                                           │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                │
│  PHASE 4: Canary Traffic Shift                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                                                                           │  │
│  │  ┌─────────────────────┐      ┌─────────────────────┐                     │  │
│  │  │   BLUE CLUSTER      │      │   GREEN CLUSTER     │                     │  │
│  │  │   (K8s 1.27)        │      │   (K8s 1.28)        │                     │  │
│  │  │   DRAINING          │      │   ACTIVE            │                     │  │
│  │  │   90% → 50% → 0%    │      │   10% → 50% → 100%  │                     │  │
│  │  └─────────────────────┘      └─────────────────────┘                     │  │
│  │                                                                           │  │
│  │  [Progressive traffic shift with monitoring]                              │  │
│  │                                                                           │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                │
│  PHASE 5: Cleanup                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                                                                           │  │
│  │                               ┌─────────────────────┐                     │  │
│  │  Blue cluster deleted         │   GREEN CLUSTER     │                     │  │
│  │  (after bake period)          │   (K8s 1.28)        │                     │  │
│  │                               │   ACTIVE            │                     │  │
│  │                               │   100% traffic      │                     │  │
│  │                               └─────────────────────┘                     │  │
│  │                                                                           │  │
│  │  [Remove blue cluster claim from Git, Crossplane deletes]                 │  │
│  │                                                                           │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────┘
```

### Implementation

```yaml
# Cluster upgrade workflow definition
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: cluster-upgrade-blue-green
spec:
  entrypoint: upgrade-cluster
  arguments:
    parameters:
      - name: cluster-name
      - name: target-version
      - name: current-version
  templates:
    - name: upgrade-cluster
      steps:
        - - name: create-green-cluster
            template: provision-cluster
            arguments:
              parameters:
                - name: cluster-suffix
                  value: "green"
                - name: k8s-version
                  value: "{{workflow.parameters.target-version}}"

        - - name: wait-for-cluster
            template: wait-cluster-ready

        - - name: bootstrap-flux
            template: bootstrap-gitops

        - - name: run-validation
            template: validate-cluster

        - - name: shift-traffic-10
            template: update-traffic-weight
            arguments:
              parameters:
                - name: weight
                  value: "10"

        - - name: monitor-10-percent
            template: monitor-metrics
            arguments:
              parameters:
                - name: duration
                  value: "10m"

        - - name: shift-traffic-50
            template: update-traffic-weight
            arguments:
              parameters:
                - name: weight
                  value: "50"

        - - name: monitor-50-percent
            template: monitor-metrics
            arguments:
              parameters:
                - name: duration
                  value: "30m"

        - - name: shift-traffic-100
            template: update-traffic-weight
            arguments:
              parameters:
                - name: weight
                  value: "100"

        - - name: cleanup-blue
            template: delete-blue-cluster
            when: "{{steps.monitor-50-percent.outputs.result}} == success"
```

---

## 5. Disaster Recovery Automation

### Business Context

Organizations need automated disaster recovery that can:
- Detect regional failures
- Automatically failover to secondary region
- Maintain data consistency
- Minimize RTO (Recovery Time Objective)

### DR Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                    DISASTER RECOVERY ARCHITECTURE                              │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│                    ┌─────────────────────────────────┐                         │
│                    │     GLOBAL TRAFFIC MANAGER      │                         │
│                    │     (Route 53 / Traffic Mgr)    │                         │
│                    │                                 │                         │
│                    │  Health Checks: /healthz        │                         │
│                    │  Failover Policy: Active-Passive│                         │
│                    └──────────────┬──────────────────┘                         │
│                                   │                                            │
│              ┌────────────────────┴────────────────────┐                       │
│              │                                         │                       │
│              ▼                                         ▼                       │
│  ┌───────────────────────────┐         ┌───────────────────────────┐           │
│  │     PRIMARY REGION        │         │    SECONDARY REGION       │           │
│  │     (us-east-1)           │         │    (us-west-2)            │           │
│  │                           │         │                           │           │
│  │  Status: ACTIVE           │         │  Status: STANDBY          │           │
│  │  ┌─────────────────────┐  │         │  ┌─────────────────────┐  │           │
│  │  │ Production Cluster  │  │         │  │ DR Cluster          │  │           │
│  │  │                     │  │         │  │                     │  │           │
│  │  │ • All workloads     │  │         │  │ • Scaled down       │  │           │
│  │  │ • Full capacity     │  │         │  │ • Ready to scale    │  │           │
│  │  │ • Receiving traffic │  │         │  │ • Synced config     │  │           │
│  │  └──────────┬──────────┘  │         │  └──────────┬──────────┘  │           │
│  │             │              │         │             │              │          │
│  │  ┌──────────▼──────────┐  │         │  ┌──────────▼──────────┐  │           │
│  │  │ Primary Database    │──┼── Async ─┼─▶│ Replica Database   │  │           │
│  │  │ (Aurora Primary)    │  │  Repl    │  │ (Aurora Replica)   │  │           │
│  │  └─────────────────────┘  │         │  └─────────────────────┘  │           │
│  │                           │         │                           │           │
│  │  ┌─────────────────────┐  │         │  ┌─────────────────────┐  │           │
│  │  │ S3 Bucket (Primary) │──┼─ CRR ───┼─▶│ S3 Bucket (Replica) │  │           │
│  │  └─────────────────────┘  │         │  └─────────────────────┘  │           │
│  └───────────────────────────┘         └───────────────────────────┘           │
│                                                                                │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                     DR AUTOMATION CONTROLLER                              │  │
│  │                                                                           │  │
│  │  Monitors:                           Actions:                             │  │
│  │  • Primary cluster health            • Scale up DR cluster                │  │
│  │  • Database replication lag          • Promote DB replica                 │  │
│  │  • Network connectivity              • Update DNS records                 │  │
│  │  • Application metrics               • Notify stakeholders                │  │
│  │                                                                           │  │
│  │  RTO Target: < 15 minutes           RPO Target: < 1 minute                │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────┘
```

### Automated Failover Configuration

```yaml
# DR Controller Custom Resource
apiVersion: dr.platform.io/v1alpha1
kind: DisasterRecoveryPlan
metadata:
  name: production-dr
spec:
  primaryCluster:
    name: prod-us-east-1
    region: us-east-1
    healthEndpoint: https://api.prod-east.company.com/healthz

  secondaryCluster:
    name: prod-us-west-2
    region: us-west-2
    healthEndpoint: https://api.prod-west.company.com/healthz

  failoverConditions:
    - type: ClusterUnreachable
      duration: 5m
    - type: HealthCheckFailed
      consecutiveFailures: 3
    - type: DatabaseReplicationLag
      threshold: 60s

  failoverActions:
    - name: scale-dr-cluster
      action: ScaleNodeGroup
      parameters:
        nodeGroup: applications
        desiredSize: 20

    - name: promote-database
      action: PromoteRDSReplica
      parameters:
        identifier: prod-dr-replica

    - name: update-dns
      action: UpdateRoute53
      parameters:
        hostedZoneId: Z1234567890
        recordName: api.company.com
        targetRegion: us-west-2

    - name: notify-team
      action: SendNotification
      parameters:
        channels:
          - slack: "#incident-response"
          - pagerduty: "production-oncall"

  recoveryActions:
    - name: resync-database
      action: ResyncDatabase
    - name: failback-traffic
      action: UpdateRoute53
      manual: true  # Requires manual approval
```

---

## 6. Regulated Healthcare Platform

### Business Context

A healthcare technology company needs to deploy HIPAA-compliant workloads across multiple environments while maintaining strict audit trails and data encryption.

### Compliance Requirements

```yaml
# policies/kyverno/hipaa/phi-protection.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: hipaa-phi-protection
  annotations:
    compliance/standard: HIPAA
    compliance/control: 164.312(a)(1)
spec:
  validationFailureAction: enforce
  rules:
    # Require encryption at rest
    - name: require-encrypted-volumes
      match:
        resources:
          kinds:
            - PersistentVolumeClaim
          namespaceSelector:
            matchLabels:
              phi-enabled: "true"
      validate:
        message: "PHI data must use encrypted storage classes"
        pattern:
          spec:
            storageClassName: "encrypted-*"

    # Require TLS for all services
    - name: require-tls-ingress
      match:
        resources:
          kinds:
            - Ingress
          namespaceSelector:
            matchLabels:
              phi-enabled: "true"
      validate:
        message: "All PHI-handling services must use TLS"
        pattern:
          spec:
            tls:
              - secretName: "?*"

    # Audit logging required
    - name: require-audit-annotations
      match:
        resources:
          kinds:
            - Deployment
          namespaceSelector:
            matchLabels:
              phi-enabled: "true"
      validate:
        message: "PHI workloads must have audit logging enabled"
        pattern:
          metadata:
            annotations:
              audit.hipaa.io/enabled: "true"
```

---

## 7. Edge Computing Fleet

### Business Context

A retail company deploys Kubernetes clusters to 500+ store locations, requiring:
- Centralized management of edge clusters
- Offline operation capability
- Bandwidth-efficient updates
- Location-specific configurations

### Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                      EDGE COMPUTING FLEET MANAGEMENT                           │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐    │
│  │                    CENTRAL CONTROL PLANE (Cloud)                        │    │
│  │                                                                         │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │    │
│  │  │ Fleet        │  │ Config       │  │ Telemetry    │                  │    │
│  │  │ Manager      │  │ Distribution │  │ Aggregator   │                  │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │    │
│  └──────────────────────────────┬─────────────────────────────────────────┘    │
│                                 │                                              │
│              ┌──────────────────┼──────────────────┐                           │
│              │                  │                  │                           │
│              ▼                  ▼                  ▼                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │
│  │  REGION: US     │  │  REGION: EU     │  │  REGION: APAC   │                 │
│  │  (150 stores)   │  │  (200 stores)   │  │  (150 stores)   │                 │
│  │                 │  │                 │  │                 │                 │
│  │ ┌─────┐ ┌─────┐ │  │ ┌─────┐ ┌─────┐ │  │ ┌─────┐ ┌─────┐ │                 │
│  │ │Store│ │Store│ │  │ │Store│ │Store│ │  │ │Store│ │Store│ │                 │
│  │ │ 001 │ │ 002 │ │  │ │ 201 │ │ 202 │ │  │ │ 401 │ │ 402 │ │                 │
│  │ └─────┘ └─────┘ │  │ └─────┘ └─────┘ │  │ └─────┘ └─────┘ │                 │
│  │    ...          │  │    ...          │  │    ...          │                 │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐    │
│  │                    EDGE CLUSTER (Per Store)                             │    │
│  │                                                                         │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │    │
│  │  │ K3s Cluster  │  │ Local Git    │  │ Edge         │                  │    │
│  │  │ (3 nodes)    │  │ Mirror       │  │ Workloads    │                  │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │    │
│  │                                                                         │    │
│  │  Workloads: POS, Inventory, Digital Signage, Analytics                  │    │
│  │  Offline: Can operate 72+ hours without connectivity                    │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Development Environments On-Demand

### Business Context

Enable developers to spin up isolated, production-like environments for feature development and testing.

### Implementation

```yaml
# Self-service environment provisioning
apiVersion: platform.company.io/v1alpha1
kind: DevEnvironment
metadata:
  name: feature-payment-v2
  labels:
    owner: jane.doe@company.com
    team: payments
spec:
  template: production-lite
  branch: feature/payment-v2
  ttl: 7d  # Auto-cleanup after 7 days

  services:
    - name: payment-service
      source:
        git: https://github.com/company/payment-service
        branch: feature/payment-v2
    - name: order-service
      source:
        image: registry.company.com/order-service:latest

  databases:
    - name: payments-db
      type: postgres
      seedData: sample-data-v1

  resources:
    requests:
      cpu: "4"
      memory: "8Gi"
    limits:
      cpu: "8"
      memory: "16Gi"

  integrations:
    github:
      prComments: true
      statusChecks: true
    slack:
      channel: "#payments-team"
```

### Workflow

```
Developer opens PR
        │
        ▼
┌─────────────────┐
│ GitHub Action   │
│ triggers        │
│ DevEnvironment  │
│ creation        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Crossplane      │
│ provisions:     │
│ • Namespace     │
│ • Databases     │
│ • Services      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Flux deploys    │
│ from feature    │
│ branch          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ PR gets URL     │───▶ https://feature-payment-v2.dev.company.com
│ comment with    │
│ environment     │
│ details         │
└────────┬────────┘
         │
         ▼
PR merged or closed
         │
         ▼
┌─────────────────┐
│ Environment     │
│ automatically   │
│ cleaned up      │
└─────────────────┘
```

---

## Summary

These use cases demonstrate the versatility and power of the Multi-Cluster GitOps Control Plane for solving real-world challenges:

| Use Case | Key Benefits |
|----------|--------------|
| Multi-Region E-Commerce | Global availability, compliance, performance |
| Financial Services | PCI-DSS compliance, audit trails, security |
| SaaS Multi-Tenant | Scalable isolation, cost allocation |
| Blue-Green Upgrades | Zero-downtime upgrades, safe rollbacks |
| Disaster Recovery | Automated failover, minimal RTO/RPO |
| Healthcare | HIPAA compliance, PHI protection |
| Edge Computing | Scale to hundreds of locations |
| Dev Environments | Self-service, cost optimization |

Each pattern builds upon the core GitOps principles while addressing specific business requirements.
