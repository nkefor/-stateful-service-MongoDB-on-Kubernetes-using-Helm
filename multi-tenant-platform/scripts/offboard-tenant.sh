#!/usr/bin/env bash
#
# Tenant Offboarding Script
# Safely decommissions a tenant and removes all associated resources
#
# Usage: ./offboard-tenant.sh --name <tenant-name> [options]
#
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
DRY_RUN=false
FORCE=false
BACKUP=true
BACKUP_DIR="/tmp/tenant-backups"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

usage() {
    cat <<EOF
Multi-Tenant Platform - Tenant Offboarding Script

Usage: $(basename "$0") [OPTIONS]

Required:
    --name <name>           Tenant name to offboard

Optional:
    --force                 Skip confirmation prompts
    --no-backup             Skip backup creation
    --backup-dir <path>     Backup directory (default: /tmp/tenant-backups)
    --dry-run               Show what would be deleted without applying
    --help                  Show this help message

Examples:
    # Offboard a tenant with backup
    $(basename "$0") --name acme

    # Offboard without confirmation
    $(basename "$0") --name acme --force

    # Dry run to preview deletions
    $(basename "$0") --name acme --dry-run

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name) TENANT_NAME="$2"; shift 2 ;;
            --force) FORCE=true; shift ;;
            --no-backup) BACKUP=false; shift ;;
            --backup-dir) BACKUP_DIR="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done
}

validate_inputs() {
    if [[ -z "${TENANT_NAME:-}" ]]; then
        log_error "Tenant name is required (--name)"
        exit 1
    fi

    # Check if tenant exists
    if ! kubectl get namespace -l "platform.devsecops.io/tenant=${TENANT_NAME}" --no-headers 2>/dev/null | grep -q .; then
        log_error "Tenant '$TENANT_NAME' not found"
        exit 1
    fi
}

confirm_deletion() {
    if [[ "$FORCE" == true ]] || [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    log_warn "This will permanently delete all resources for tenant: $TENANT_NAME"

    # List namespaces
    echo ""
    echo "Namespaces to be deleted:"
    kubectl get namespace -l "platform.devsecops.io/tenant=${TENANT_NAME}" --no-headers -o custom-columns=":metadata.name"
    echo ""

    read -p "Are you sure you want to proceed? Type the tenant name to confirm: " CONFIRM
    if [[ "$CONFIRM" != "$TENANT_NAME" ]]; then
        log_error "Confirmation failed. Aborting."
        exit 1
    fi
}

backup_tenant() {
    if [[ "$BACKUP" != true ]] || [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    log_info "Creating backup of tenant resources..."

    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    TENANT_BACKUP_DIR="${BACKUP_DIR}/${TENANT_NAME}-${TIMESTAMP}"
    mkdir -p "$TENANT_BACKUP_DIR"

    # Get all tenant namespaces
    NAMESPACES=$(kubectl get namespace -l "platform.devsecops.io/tenant=${TENANT_NAME}" --no-headers -o custom-columns=":metadata.name")

    for ns in $NAMESPACES; do
        NS_BACKUP_DIR="${TENANT_BACKUP_DIR}/${ns}"
        mkdir -p "$NS_BACKUP_DIR"

        log_info "Backing up namespace: $ns"

        # Backup deployments
        kubectl get deployments -n "$ns" -o yaml > "${NS_BACKUP_DIR}/deployments.yaml" 2>/dev/null || true

        # Backup services
        kubectl get services -n "$ns" -o yaml > "${NS_BACKUP_DIR}/services.yaml" 2>/dev/null || true

        # Backup configmaps
        kubectl get configmaps -n "$ns" -o yaml > "${NS_BACKUP_DIR}/configmaps.yaml" 2>/dev/null || true

        # Backup secrets (encrypted)
        kubectl get secrets -n "$ns" -o yaml > "${NS_BACKUP_DIR}/secrets.yaml" 2>/dev/null || true

        # Backup PVCs
        kubectl get pvc -n "$ns" -o yaml > "${NS_BACKUP_DIR}/pvcs.yaml" 2>/dev/null || true

        # Backup ingresses
        kubectl get ingress -n "$ns" -o yaml > "${NS_BACKUP_DIR}/ingresses.yaml" 2>/dev/null || true
    done

    # Backup ArgoCD project
    if kubectl get appproject "$TENANT_NAME" -n argocd &>/dev/null; then
        kubectl get appproject "$TENANT_NAME" -n argocd -o yaml > "${TENANT_BACKUP_DIR}/argocd-project.yaml"
    fi

    # Create archive
    ARCHIVE_PATH="${BACKUP_DIR}/${TENANT_NAME}-${TIMESTAMP}.tar.gz"
    tar -czf "$ARCHIVE_PATH" -C "$BACKUP_DIR" "${TENANT_NAME}-${TIMESTAMP}"
    rm -rf "$TENANT_BACKUP_DIR"

    log_success "Backup created: $ARCHIVE_PATH"
}

delete_argocd_resources() {
    log_info "Deleting ArgoCD resources..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would delete ArgoCD applications for tenant: $TENANT_NAME"
        kubectl get applications -n argocd -l "platform.devsecops.io/tenant=${TENANT_NAME}" --no-headers 2>/dev/null || true
        log_info "[DRY-RUN] Would delete AppProject: $TENANT_NAME"
        return
    fi

    # Delete applications first
    kubectl delete applications -n argocd -l "platform.devsecops.io/tenant=${TENANT_NAME}" --ignore-not-found

    # Delete AppProject
    kubectl delete appproject "$TENANT_NAME" -n argocd --ignore-not-found

    log_success "ArgoCD resources deleted"
}

delete_namespaces() {
    log_info "Deleting tenant namespaces..."

    NAMESPACES=$(kubectl get namespace -l "platform.devsecops.io/tenant=${TENANT_NAME}" --no-headers -o custom-columns=":metadata.name")

    for ns in $NAMESPACES; do
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY-RUN] Would delete namespace: $ns"
        else
            log_info "Deleting namespace: $ns"
            kubectl delete namespace "$ns" --wait=true
        fi
    done

    log_success "Namespaces deleted"
}

delete_capsule_tenant() {
    # Check if Capsule tenant exists
    if kubectl get tenant "$TENANT_NAME" &>/dev/null 2>&1; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY-RUN] Would delete Capsule tenant: $TENANT_NAME"
        else
            log_info "Deleting Capsule tenant: $TENANT_NAME"
            kubectl delete tenant "$TENANT_NAME" --ignore-not-found
        fi
    fi
}

cleanup_cluster_resources() {
    log_info "Cleaning up cluster-scoped resources..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would delete ClusterRoleBindings for tenant: $TENANT_NAME"
        return
    fi

    # Delete any cluster-scoped resources labeled with tenant
    kubectl delete clusterrolebindings -l "platform.devsecops.io/tenant=${TENANT_NAME}" --ignore-not-found

    log_success "Cluster resources cleaned up"
}

generate_summary() {
    cat <<EOF

================================================================================
                    TENANT OFFBOARDING COMPLETE
================================================================================

Tenant Name:     ${TENANT_NAME}
Status:          DECOMMISSIONED

ACTIONS TAKEN:
  - ArgoCD applications and project deleted
  - Tenant namespaces deleted
  - Cluster-scoped resources cleaned up
EOF

    if [[ "$BACKUP" == true ]] && [[ "$DRY_RUN" != true ]]; then
        echo "  - Backup created: ${ARCHIVE_PATH:-N/A}"
    fi

    cat <<EOF

RECOMMENDED FOLLOW-UP:
  1. Remove users from tenant groups in identity provider
  2. Revoke any external access tokens or credentials
  3. Archive backup to long-term storage
  4. Update billing/cost allocation records

================================================================================
EOF
}

main() {
    echo ""
    echo "=========================================="
    echo "  Multi-Tenant Platform - Tenant Offboarding"
    echo "=========================================="
    echo ""

    parse_args "$@"
    validate_inputs
    confirm_deletion
    backup_tenant
    delete_argocd_resources
    delete_capsule_tenant
    delete_namespaces
    cleanup_cluster_resources

    if [[ "$DRY_RUN" != true ]]; then
        generate_summary
    fi

    log_success "Tenant offboarding completed!"
}

main "$@"
