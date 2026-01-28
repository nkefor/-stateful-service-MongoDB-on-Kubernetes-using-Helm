#!/usr/bin/env bash
#
# Multi-Tenant DevSecOps Platform Installation Script
# Installs all platform components for multi-tenant Kubernetes environment
#
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(dirname "$SCRIPT_DIR")"

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Default configuration
DOMAIN="platform.example.com"
INSTALL_CAPSULE=false
INSTALL_ARGOCD=true
INSTALL_KYVERNO=true
INSTALL_OBSERVABILITY=true
DRY_RUN=false

usage() {
    cat <<EOF
Multi-Tenant DevSecOps Platform - Installation Script

Usage: $(basename "$0") [OPTIONS]

Options:
    --domain <domain>       Platform domain (default: platform.example.com)
    --with-capsule          Install Capsule for tenant management
    --without-argocd        Skip ArgoCD installation
    --without-kyverno       Skip Kyverno installation
    --without-observability Skip observability stack
    --dry-run               Show what would be installed
    --help                  Show this help message

Example:
    $(basename "$0") --domain myplatform.com --with-capsule

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain) DOMAIN="$2"; shift 2 ;;
            --with-capsule) INSTALL_CAPSULE=true; shift ;;
            --without-argocd) INSTALL_ARGOCD=false; shift ;;
            --without-kyverno) INSTALL_KYVERNO=false; shift ;;
            --without-observability) INSTALL_OBSERVABILITY=false; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

    command -v kubectl &>/dev/null || missing+=("kubectl")
    command -v helm &>/dev/null || missing+=("helm")
    command -v git &>/dev/null || missing+=("git")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi

    if ! kubectl cluster-info &>/dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

add_helm_repos() {
    log_info "Adding Helm repositories..."

    helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
    helm repo add kyverno https://kyverno.github.io/kyverno 2>/dev/null || true
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
    helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
    helm repo add capsule https://projectcapsule.github.io/charts 2>/dev/null || true
    helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true

    helm repo update

    log_success "Helm repositories configured"
}

install_cert_manager() {
    log_info "Installing cert-manager..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install cert-manager"
        return
    fi

    if kubectl get namespace cert-manager &>/dev/null; then
        log_warn "cert-manager already installed, skipping"
        return
    fi

    helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --set installCRDs=true \
        --wait

    log_success "cert-manager installed"
}

install_platform_base() {
    log_info "Installing platform base resources..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would apply base resources"
        kubectl apply -k "${PLATFORM_DIR}/base" --dry-run=client
        return
    fi

    kubectl apply -k "${PLATFORM_DIR}/base"

    log_success "Platform base resources installed"
}

install_capsule() {
    if [[ "$INSTALL_CAPSULE" != true ]]; then
        log_info "Skipping Capsule installation"
        return
    fi

    log_info "Installing Capsule..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install Capsule"
        return
    fi

    helm install capsule capsule/capsule \
        --namespace capsule-system \
        --create-namespace \
        --set manager.resources.requests.cpu=100m \
        --set manager.resources.requests.memory=128Mi \
        --wait

    log_success "Capsule installed"
}

install_kyverno() {
    if [[ "$INSTALL_KYVERNO" != true ]]; then
        log_info "Skipping Kyverno installation"
        return
    fi

    log_info "Installing Kyverno..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install Kyverno and policies"
        return
    fi

    if kubectl get namespace kyverno &>/dev/null; then
        log_warn "Kyverno already installed, upgrading..."
    fi

    helm upgrade --install kyverno kyverno/kyverno \
        --namespace kyverno \
        --create-namespace \
        --set replicaCount=3 \
        --set resources.requests.cpu=100m \
        --set resources.requests.memory=256Mi \
        --wait

    # Apply policies
    log_info "Applying Kyverno policies..."
    kubectl apply -f "${PLATFORM_DIR}/policies/kyverno/"

    log_success "Kyverno and policies installed"
}

install_argocd() {
    if [[ "$INSTALL_ARGOCD" != true ]]; then
        log_info "Skipping ArgoCD installation"
        return
    fi

    log_info "Installing ArgoCD..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install ArgoCD"
        return
    fi

    if kubectl get namespace argocd &>/dev/null; then
        log_warn "ArgoCD already installed, upgrading..."
    fi

    # Update domain in values
    sed -i "s/platform.example.com/${DOMAIN}/g" "${PLATFORM_DIR}/gitops/argocd/argocd-values.yaml"

    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd \
        --create-namespace \
        -f "${PLATFORM_DIR}/gitops/argocd/argocd-values.yaml" \
        --wait

    # Get initial admin password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    log_info "ArgoCD admin password: ${ARGOCD_PASSWORD}"
    log_warn "Please change the admin password after first login!"

    log_success "ArgoCD installed"
}

install_observability() {
    if [[ "$INSTALL_OBSERVABILITY" != true ]]; then
        log_info "Skipping observability stack installation"
        return
    fi

    log_info "Installing observability stack..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install Prometheus, Loki, and Grafana"
        return
    fi

    # Update domain in values
    sed -i "s/platform.example.com/${DOMAIN}/g" "${PLATFORM_DIR}/observability/prometheus/prometheus-values.yaml"

    # Install Prometheus stack
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace observability \
        --create-namespace \
        -f "${PLATFORM_DIR}/observability/prometheus/prometheus-values.yaml" \
        --wait

    # Install Loki stack
    helm upgrade --install loki grafana/loki-stack \
        --namespace observability \
        -f "${PLATFORM_DIR}/observability/loki/loki-values.yaml" \
        --wait

    # Apply Grafana dashboards
    kubectl apply -f "${PLATFORM_DIR}/observability/grafana/"

    # Apply Alertmanager config
    kubectl apply -f "${PLATFORM_DIR}/observability/alertmanager/"

    # Get Grafana password
    GRAFANA_PASSWORD=$(kubectl get secret -n observability prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d)
    log_info "Grafana admin password: ${GRAFANA_PASSWORD}"

    log_success "Observability stack installed"
}

apply_network_policies() {
    log_info "Applying platform network policies..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would apply network policies"
        return
    fi

    kubectl apply -f "${PLATFORM_DIR}/base/network-policies/"

    log_success "Network policies applied"
}

print_summary() {
    cat <<EOF

================================================================================
        MULTI-TENANT DEVSECOPS PLATFORM INSTALLATION COMPLETE
================================================================================

Platform Domain: ${DOMAIN}

INSTALLED COMPONENTS:
  - Platform base resources
  - cert-manager for TLS
EOF

    [[ "$INSTALL_CAPSULE" == true ]] && echo "  - Capsule for tenant management"
    [[ "$INSTALL_KYVERNO" == true ]] && echo "  - Kyverno policy engine with policies"
    [[ "$INSTALL_ARGOCD" == true ]] && echo "  - ArgoCD for GitOps"
    [[ "$INSTALL_OBSERVABILITY" == true ]] && echo "  - Prometheus, Loki, Grafana for observability"

    cat <<EOF

ACCESS URLS:
EOF

    [[ "$INSTALL_ARGOCD" == true ]] && echo "  - ArgoCD:     https://argocd.${DOMAIN}"
    [[ "$INSTALL_OBSERVABILITY" == true ]] && echo "  - Grafana:    https://grafana.${DOMAIN}"
    [[ "$INSTALL_OBSERVABILITY" == true ]] && echo "  - Prometheus: https://prometheus.${DOMAIN}"

    cat <<EOF

NEXT STEPS:
  1. Configure DNS records for platform services
  2. Update TLS certificates (or use Let's Encrypt)
  3. Configure identity provider for SSO
  4. Onboard your first tenant:

     ./scripts/onboard-tenant.sh \\
       --name my-tenant \\
       --tier starter \\
       --owner-email admin@example.com

DOCUMENTATION:
  - Platform docs: multi-tenant-platform/docs/README.md
  - Tenant guide:  multi-tenant-platform/docs/tenant-guide.md

================================================================================
EOF
}

main() {
    echo ""
    echo "=========================================="
    echo "  Multi-Tenant DevSecOps Platform Setup"
    echo "=========================================="
    echo ""

    parse_args "$@"

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "Running in DRY-RUN mode"
    fi

    check_prerequisites
    add_helm_repos
    install_cert_manager
    install_platform_base
    install_capsule
    install_kyverno
    install_argocd
    install_observability
    apply_network_policies

    if [[ "$DRY_RUN" != true ]]; then
        print_summary
    fi

    log_success "Platform installation completed!"
}

main "$@"
