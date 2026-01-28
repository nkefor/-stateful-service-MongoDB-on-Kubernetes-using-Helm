#!/usr/bin/env bash
#
# Tenant Onboarding Script
# Provisions a new tenant with namespaces, RBAC, quotas, network policies, and GitOps
#
# Usage: ./onboard-tenant.sh --name <tenant-name> --tier <tier> --owner-email <email> [options]
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="${PLATFORM_DIR}/templates"

# Default values
ENVIRONMENTS="dev"
DRY_RUN=false
VERBOSE=false
CAPSULE_ENABLED=false

# Tier resource definitions
declare -A TIER_CPU_REQUESTS=(
    ["free"]="2"
    ["starter"]="8"
    ["professional"]="32"
    ["enterprise"]="128"
)

declare -A TIER_MEMORY_REQUESTS=(
    ["free"]="4Gi"
    ["starter"]="16Gi"
    ["professional"]="64Gi"
    ["enterprise"]="256Gi"
)

declare -A TIER_MAX_PODS=(
    ["free"]="20"
    ["starter"]="50"
    ["professional"]="200"
    ["enterprise"]="1000"
)

declare -A TIER_MAX_NAMESPACES=(
    ["free"]="2"
    ["starter"]="5"
    ["professional"]="15"
    ["enterprise"]="50"
)

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Usage information
usage() {
    cat <<EOF
Multi-Tenant Platform - Tenant Onboarding Script

Usage: $(basename "$0") [OPTIONS]

Required:
    --name <name>           Tenant name (lowercase, alphanumeric, max 20 chars)
    --tier <tier>           Service tier: free, starter, professional, enterprise
    --owner-email <email>   Owner email address

Optional:
    --owner-team <team>         Owner team name
    --cost-center <code>        Cost center code for billing
    --environments <envs>       Comma-separated environments (default: dev)
                                Options: dev, staging, prod
    --git-repo <url>            Git repository URL for GitOps
    --git-branch <branch>       Git branch (default: main)
    --capsule                   Use Capsule for tenant management
    --dry-run                   Show what would be created without applying
    --verbose                   Enable verbose output
    --help                      Show this help message

Examples:
    # Onboard a free tier tenant with dev environment
    $(basename "$0") --name acme --tier free --owner-email admin@acme.com

    # Onboard a professional tier tenant with all environments
    $(basename "$0") --name bigcorp --tier professional \\
        --owner-email platform@bigcorp.com \\
        --environments dev,staging,prod \\
        --git-repo https://github.com/bigcorp/k8s-apps

    # Dry run to preview changes
    $(basename "$0") --name test --tier starter \\
        --owner-email test@example.com --dry-run

EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                TENANT_NAME="$2"
                shift 2
                ;;
            --tier)
                TIER="$2"
                shift 2
                ;;
            --owner-email)
                OWNER_EMAIL="$2"
                shift 2
                ;;
            --owner-team)
                OWNER_TEAM="$2"
                shift 2
                ;;
            --cost-center)
                COST_CENTER="$2"
                shift 2
                ;;
            --environments)
                ENVIRONMENTS="$2"
                shift 2
                ;;
            --git-repo)
                GIT_REPO="$2"
                shift 2
                ;;
            --git-branch)
                GIT_BRANCH="$2"
                shift 2
                ;;
            --capsule)
                CAPSULE_ENABLED=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Validate inputs
validate_inputs() {
    log_info "Validating inputs..."

    # Check required parameters
    if [[ -z "${TENANT_NAME:-}" ]]; then
        log_error "Tenant name is required (--name)"
        exit 1
    fi

    if [[ -z "${TIER:-}" ]]; then
        log_error "Tier is required (--tier)"
        exit 1
    fi

    if [[ -z "${OWNER_EMAIL:-}" ]]; then
        log_error "Owner email is required (--owner-email)"
        exit 1
    fi

    # Validate tenant name format
    if ! [[ "$TENANT_NAME" =~ ^[a-z][a-z0-9-]{0,19}$ ]]; then
        log_error "Tenant name must be lowercase, start with a letter, and be max 20 characters"
        exit 1
    fi

    # Validate tier
    if [[ ! "${TIER_CPU_REQUESTS[$TIER]+exists}" ]]; then
        log_error "Invalid tier: $TIER. Must be one of: free, starter, professional, enterprise"
        exit 1
    fi

    # Validate email format
    if ! [[ "$OWNER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email format: $OWNER_EMAIL"
        exit 1
    fi

    # Validate environments
    IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"
    for env in "${ENV_ARRAY[@]}"; do
        if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
            log_error "Invalid environment: $env. Must be one of: dev, staging, prod"
            exit 1
        fi
    done

    # Check if tenant already exists
    if kubectl get namespace "${TENANT_NAME}-dev" &>/dev/null; then
        log_error "Tenant '$TENANT_NAME' already exists"
        exit 1
    fi

    log_success "Input validation passed"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check kubectl
    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl is required but not installed"
        exit 1
    fi

    # Check cluster connectivity
    if ! kubectl cluster-info &>/dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    # Check helm
    if ! command -v helm &>/dev/null; then
        log_error "helm is required but not installed"
        exit 1
    fi

    # Check yq
    if ! command -v yq &>/dev/null; then
        log_warn "yq is not installed. Some features may not work."
    fi

    # Check if ArgoCD is installed
    if ! kubectl get namespace argocd &>/dev/null; then
        log_warn "ArgoCD namespace not found. GitOps features will be skipped."
        ARGOCD_INSTALLED=false
    else
        ARGOCD_INSTALLED=true
    fi

    # Check if Capsule is installed (if requested)
    if [[ "$CAPSULE_ENABLED" == true ]]; then
        if ! kubectl get crd tenants.capsule.clastix.io &>/dev/null; then
            log_error "Capsule CRD not found. Install Capsule or remove --capsule flag."
            exit 1
        fi
    fi

    log_success "Prerequisites check passed"
}

# Create namespaces for tenant
create_namespaces() {
    log_info "Creating namespaces for tenant: $TENANT_NAME"

    IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"
    for env in "${ENV_ARRAY[@]}"; do
        NS_NAME="${TENANT_NAME}-${env}"

        cat <<EOF | apply_manifest "Namespace $NS_NAME"
apiVersion: v1
kind: Namespace
metadata:
  name: ${NS_NAME}
  labels:
    app.kubernetes.io/name: ${TENANT_NAME}
    platform.devsecops.io/tenant: ${TENANT_NAME}
    platform.devsecops.io/tier: ${TIER}
    platform.devsecops.io/environment: ${env}
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
  annotations:
    platform.devsecops.io/owner-email: "${OWNER_EMAIL}"
    platform.devsecops.io/cost-center: "${COST_CENTER:-unassigned}"
    platform.devsecops.io/created-at: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
EOF
    done

    log_success "Namespaces created"
}

# Create RBAC for tenant
create_rbac() {
    log_info "Creating RBAC for tenant: $TENANT_NAME"

    IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"
    for env in "${ENV_ARRAY[@]}"; do
        NS_NAME="${TENANT_NAME}-${env}"

        # Tenant Admin Role
        cat <<EOF | apply_manifest "Role tenant-admin in $NS_NAME"
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tenant-admin
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
rules:
  - apiGroups: ["", "apps", "batch", "networking.k8s.io", "autoscaling", "policy"]
    resources: ["*"]
    verbs: ["*"]
  - apiGroups: [""]
    resources: ["resourcequotas", "limitranges"]
    verbs: ["get", "list", "watch"]
EOF

        # Tenant Admin RoleBinding
        cat <<EOF | apply_manifest "RoleBinding tenant-admin-binding in $NS_NAME"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-admin-binding
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: tenant-admin
subjects:
  - kind: Group
    name: ${TENANT_NAME}-admins
    apiGroup: rbac.authorization.k8s.io
EOF

        # Tenant Developer Role
        cat <<EOF | apply_manifest "Role tenant-developer in $NS_NAME"
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tenant-developer
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
rules:
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "replicasets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods", "pods/log", "services", "configmaps", "persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods/exec", "pods/portforward"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["autoscaling"]
    resources: ["horizontalpodautoscalers"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["get", "list", "watch"]
EOF

        # Tenant Developer RoleBinding
        cat <<EOF | apply_manifest "RoleBinding tenant-developer-binding in $NS_NAME"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-developer-binding
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: tenant-developer
subjects:
  - kind: Group
    name: ${TENANT_NAME}-developers
    apiGroup: rbac.authorization.k8s.io
EOF

        # CI/CD Service Account
        cat <<EOF | apply_manifest "ServiceAccount ${TENANT_NAME}-cicd in $NS_NAME"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${TENANT_NAME}-cicd
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
    platform.devsecops.io/purpose: cicd
EOF

        # CI/CD RoleBinding
        cat <<EOF | apply_manifest "RoleBinding ${TENANT_NAME}-cicd-binding in $NS_NAME"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${TENANT_NAME}-cicd-binding
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: tenant-developer
subjects:
  - kind: ServiceAccount
    name: ${TENANT_NAME}-cicd
    namespace: ${NS_NAME}
EOF
    done

    log_success "RBAC created"
}

# Create resource quotas
create_quotas() {
    log_info "Creating resource quotas for tenant: $TENANT_NAME (tier: $TIER)"

    IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"
    for env in "${ENV_ARRAY[@]}"; do
        NS_NAME="${TENANT_NAME}-${env}"

        cat <<EOF | apply_manifest "ResourceQuota in $NS_NAME"
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
    platform.devsecops.io/tier: ${TIER}
spec:
  hard:
    requests.cpu: "${TIER_CPU_REQUESTS[$TIER]}"
    requests.memory: "${TIER_MEMORY_REQUESTS[$TIER]}"
    limits.cpu: "$((${TIER_CPU_REQUESTS[$TIER]%[^0-9]*} * 2))"
    limits.memory: "$((${TIER_MEMORY_REQUESTS[$TIER]%[^0-9]*} * 2))Gi"
    pods: "${TIER_MAX_PODS[$TIER]}"
    persistentvolumeclaims: "10"
    services: "20"
    secrets: "50"
    configmaps: "50"
EOF

        cat <<EOF | apply_manifest "LimitRange in $NS_NAME"
apiVersion: v1
kind: LimitRange
metadata:
  name: tenant-limits
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
    platform.devsecops.io/tier: ${TIER}
spec:
  limits:
    - type: Container
      default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
      max:
        cpu: "2"
        memory: "4Gi"
      min:
        cpu: "10m"
        memory: "16Mi"
    - type: Pod
      max:
        cpu: "4"
        memory: "8Gi"
    - type: PersistentVolumeClaim
      max:
        storage: "50Gi"
      min:
        storage: "1Gi"
EOF
    done

    log_success "Resource quotas created"
}

# Create network policies
create_network_policies() {
    log_info "Creating network policies for tenant: $TENANT_NAME"

    IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"
    for env in "${ENV_ARRAY[@]}"; do
        NS_NAME="${TENANT_NAME}-${env}"

        # Default deny all
        cat <<EOF | apply_manifest "NetworkPolicy default-deny in $NS_NAME"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
EOF

        # Allow DNS
        cat <<EOF | apply_manifest "NetworkPolicy allow-dns in $NS_NAME"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
EOF

        # Allow same namespace
        cat <<EOF | apply_manifest "NetworkPolicy allow-same-namespace in $NS_NAME"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector: {}
  egress:
    - to:
        - podSelector: {}
EOF

        # Allow same tenant (cross-namespace)
        cat <<EOF | apply_manifest "NetworkPolicy allow-same-tenant in $NS_NAME"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-tenant
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              platform.devsecops.io/tenant: ${TENANT_NAME}
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              platform.devsecops.io/tenant: ${TENANT_NAME}
EOF

        # Allow ingress controller
        cat <<EOF | apply_manifest "NetworkPolicy allow-ingress-controller in $NS_NAME"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-controller
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
EOF

        # Allow external HTTPS
        cat <<EOF | apply_manifest "NetworkPolicy allow-external-https in $NS_NAME"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-https
  namespace: ${NS_NAME}
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16
      ports:
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 80
EOF
    done

    log_success "Network policies created"
}

# Create ArgoCD AppProject
create_argocd_project() {
    if [[ "$ARGOCD_INSTALLED" != true ]]; then
        log_warn "Skipping ArgoCD project creation (ArgoCD not installed)"
        return
    fi

    log_info "Creating ArgoCD AppProject for tenant: $TENANT_NAME"

    # Build namespace list
    NAMESPACE_LIST=""
    IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"
    for env in "${ENV_ARRAY[@]}"; do
        NAMESPACE_LIST="${NAMESPACE_LIST}    - namespace: ${TENANT_NAME}-${env}
      server: https://kubernetes.default.svc
"
    done

    cat <<EOF | apply_manifest "AppProject $TENANT_NAME in argocd"
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: ${TENANT_NAME}
  namespace: argocd
  labels:
    platform.devsecops.io/tenant: ${TENANT_NAME}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  description: "GitOps project for tenant ${TENANT_NAME}"
  sourceRepos:
    - "${GIT_REPO:-https://github.com/${TENANT_NAME}/*}"
  destinations:
${NAMESPACE_LIST}
  clusterResourceBlacklist:
    - group: ""
      kind: Namespace
    - group: rbac.authorization.k8s.io
      kind: ClusterRole
    - group: rbac.authorization.k8s.io
      kind: ClusterRoleBinding
  namespaceResourceWhitelist:
    - group: ""
      kind: ConfigMap
    - group: ""
      kind: Endpoints
    - group: ""
      kind: PersistentVolumeClaim
    - group: ""
      kind: Pod
    - group: ""
      kind: Secret
    - group: ""
      kind: Service
    - group: ""
      kind: ServiceAccount
    - group: apps
      kind: Deployment
    - group: apps
      kind: ReplicaSet
    - group: apps
      kind: StatefulSet
    - group: batch
      kind: Job
    - group: batch
      kind: CronJob
    - group: networking.k8s.io
      kind: Ingress
    - group: autoscaling
      kind: HorizontalPodAutoscaler
    - group: policy
      kind: PodDisruptionBudget
  roles:
    - name: tenant-admin
      description: Full access to tenant applications
      policies:
        - p, proj:${TENANT_NAME}:tenant-admin, applications, *, ${TENANT_NAME}/*, allow
      groups:
        - ${TENANT_NAME}-admins
    - name: tenant-developer
      description: Can deploy and view applications
      policies:
        - p, proj:${TENANT_NAME}:tenant-developer, applications, get, ${TENANT_NAME}/*, allow
        - p, proj:${TENANT_NAME}:tenant-developer, applications, sync, ${TENANT_NAME}/*, allow
      groups:
        - ${TENANT_NAME}-developers
EOF

    log_success "ArgoCD AppProject created"
}

# Apply manifest helper
apply_manifest() {
    local description="$1"
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would create: $description"
        if [[ "$VERBOSE" == true ]]; then
            cat
        else
            cat > /dev/null
        fi
    else
        if [[ "$VERBOSE" == true ]]; then
            kubectl apply -f - | while read -r line; do
                log_info "$line"
            done
        else
            kubectl apply -f - > /dev/null
        fi
        log_info "Created: $description"
    fi
}

# Generate tenant summary
generate_summary() {
    log_info "Generating tenant summary..."

    IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"

    cat <<EOF

================================================================================
                    TENANT ONBOARDING COMPLETE
================================================================================

Tenant Name:     ${TENANT_NAME}
Tier:            ${TIER}
Owner Email:     ${OWNER_EMAIL}
Owner Team:      ${OWNER_TEAM:-Not specified}
Cost Center:     ${COST_CENTER:-unassigned}

NAMESPACES CREATED:
EOF

    for env in "${ENV_ARRAY[@]}"; do
        echo "  - ${TENANT_NAME}-${env}"
    done

    cat <<EOF

RESOURCE QUOTAS:
  CPU Requests:    ${TIER_CPU_REQUESTS[$TIER]}
  Memory Requests: ${TIER_MEMORY_REQUESTS[$TIER]}
  Max Pods:        ${TIER_MAX_PODS[$TIER]}

ACCESS GROUPS:
  Admins:          ${TENANT_NAME}-admins
  Developers:      ${TENANT_NAME}-developers
  Viewers:         ${TENANT_NAME}-viewers

CI/CD SERVICE ACCOUNT:
EOF

    for env in "${ENV_ARRAY[@]}"; do
        echo "  ${TENANT_NAME}-${env}/${TENANT_NAME}-cicd"
    done

    if [[ "$ARGOCD_INSTALLED" == true ]]; then
        cat <<EOF

GITOPS:
  ArgoCD Project:  ${TENANT_NAME}
  Repository:      ${GIT_REPO:-https://github.com/${TENANT_NAME}/*}
EOF
    fi

    cat <<EOF

NEXT STEPS:
  1. Add users to the appropriate groups in your identity provider
  2. Configure Git repository access for CI/CD
  3. Deploy your first application using the pipeline template
  4. Review the platform documentation for best practices

USEFUL COMMANDS:
  # Check namespace resources
  kubectl get all -n ${TENANT_NAME}-dev

  # Check resource usage
  kubectl describe resourcequota -n ${TENANT_NAME}-dev

  # View network policies
  kubectl get networkpolicy -n ${TENANT_NAME}-dev

================================================================================
EOF
}

# Main function
main() {
    echo ""
    echo "=========================================="
    echo "  Multi-Tenant Platform - Tenant Onboarding"
    echo "=========================================="
    echo ""

    parse_args "$@"
    validate_inputs
    check_prerequisites

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "Running in DRY-RUN mode - no changes will be applied"
    fi

    create_namespaces
    create_rbac
    create_quotas
    create_network_policies
    create_argocd_project

    if [[ "$DRY_RUN" != true ]]; then
        generate_summary
    fi

    log_success "Tenant onboarding completed successfully!"
}

# Run main function
main "$@"
