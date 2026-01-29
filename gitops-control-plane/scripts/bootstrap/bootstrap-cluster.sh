#!/bin/bash
# Bootstrap script for new workload clusters
# This script installs Flux and configures GitOps on a newly provisioned cluster

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
GITHUB_ORG="${GITHUB_ORG:-YOUR_ORG}"
GITHUB_REPO="${GITHUB_REPO:-gitops-control-plane}"
FLUX_VERSION="${FLUX_VERSION:-2.1.0}"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi

    # Check flux
    if ! command -v flux &> /dev/null; then
        log_error "flux CLI is not installed"
        exit 1
    fi

    # Check helm
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed"
        exit 1
    fi

    # Check GitHub token
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_error "GITHUB_TOKEN environment variable is not set"
        exit 1
    fi

    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    log_info "All prerequisites met"
}

get_cluster_info() {
    CLUSTER_NAME=$(kubectl config current-context)
    log_info "Bootstrapping cluster: $CLUSTER_NAME"
}

install_flux() {
    log_info "Installing Flux..."

    flux bootstrap github \
        --owner="${GITHUB_ORG}" \
        --repository="${GITHUB_REPO}" \
        --branch=main \
        --path="./gitops/flux/clusters/${CLUSTER_TYPE}" \
        --personal \
        --token-auth

    log_info "Flux installed successfully"
}

configure_flux_sources() {
    log_info "Configuring Flux sources..."

    # Wait for flux to be ready
    kubectl wait --for=condition=ready pod -l app=source-controller -n flux-system --timeout=300s

    # Apply additional sources if needed
    log_info "Flux sources configured"
}

install_prerequisites() {
    log_info "Installing prerequisites..."

    # Create namespaces
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace security --dry-run=client -o yaml | kubectl apply -f -

    # Label namespaces
    kubectl label namespace monitoring prometheus-scrape=true --overwrite
    kubectl label namespace security policy-enforcement=true --overwrite

    log_info "Prerequisites installed"
}

verify_installation() {
    log_info "Verifying installation..."

    # Check Flux controllers
    flux check

    # Check reconciliation
    flux get sources git
    flux get kustomizations

    log_info "Installation verified"
}

print_next_steps() {
    echo ""
    echo "=========================================="
    echo " Cluster Bootstrap Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Verify Flux is syncing: flux get all -A"
    echo "2. Check for any reconciliation errors: flux logs -A"
    echo "3. Apply environment-specific configurations"
    echo ""
    echo "Useful commands:"
    echo "  - Force reconciliation: flux reconcile source git flux-system"
    echo "  - Check status: flux get all -A --status-selector ready=false"
    echo "  - View logs: flux logs -f -A"
    echo ""
}

# Main
main() {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <cluster-type> [cluster-name]"
        echo "  cluster-type: dev, staging, prod"
        echo "  cluster-name: optional, defaults to current context"
        exit 1
    fi

    CLUSTER_TYPE=$1
    CLUSTER_NAME=${2:-$(kubectl config current-context)}

    log_info "Starting bootstrap for ${CLUSTER_TYPE} cluster: ${CLUSTER_NAME}"

    check_prerequisites
    get_cluster_info
    install_prerequisites
    install_flux
    configure_flux_sources
    verify_installation
    print_next_steps

    log_info "Bootstrap complete!"
}

main "$@"
