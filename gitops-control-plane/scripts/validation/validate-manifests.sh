#!/bin/bash
# Validate Kubernetes manifests before committing
# Run this script as a pre-commit hook or in CI/CD

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)); }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; ((ERRORS++)); }

# Find all YAML files
find_yaml_files() {
    find . -type f \( -name "*.yaml" -o -name "*.yml" \) \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        -not -path "./.terraform/*"
}

# Validate YAML syntax
validate_yaml_syntax() {
    log_info "Validating YAML syntax..."
    while IFS= read -r file; do
        if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            log_error "Invalid YAML syntax: $file"
        fi
    done < <(find_yaml_files)
}

# Validate Kubernetes manifests with kubeconform
validate_kubernetes_manifests() {
    log_info "Validating Kubernetes manifests..."

    if ! command -v kubeconform &> /dev/null; then
        log_warn "kubeconform not installed, skipping Kubernetes validation"
        return
    fi

    while IFS= read -r file; do
        # Skip Kustomize and Helm files
        if grep -q "^apiVersion:" "$file" 2>/dev/null; then
            if ! kubeconform -strict -ignore-missing-schemas "$file" 2>/dev/null; then
                log_error "Invalid Kubernetes manifest: $file"
            fi
        fi
    done < <(find_yaml_files)
}

# Validate Kyverno policies
validate_kyverno_policies() {
    log_info "Validating Kyverno policies..."

    if ! command -v kyverno &> /dev/null; then
        log_warn "kyverno CLI not installed, skipping policy validation"
        return
    fi

    if [ -d "./policies/kyverno" ]; then
        kyverno validate ./policies/kyverno/ || log_error "Kyverno policy validation failed"
    fi
}

# Validate Helm charts
validate_helm_charts() {
    log_info "Validating Helm charts..."

    if ! command -v helm &> /dev/null; then
        log_warn "helm not installed, skipping Helm validation"
        return
    fi

    for chart in ./helm-charts/*/; do
        if [ -f "${chart}Chart.yaml" ]; then
            if ! helm lint "$chart" --quiet; then
                log_error "Helm chart validation failed: $chart"
            fi
        fi
    done
}

# Validate Terraform configurations
validate_terraform() {
    log_info "Validating Terraform configurations..."

    if ! command -v terraform &> /dev/null; then
        log_warn "terraform not installed, skipping Terraform validation"
        return
    fi

    for tf_dir in ./terraform/modules/*/ ./terraform/environments/*/; do
        if [ -f "${tf_dir}main.tf" ]; then
            if ! terraform -chdir="$tf_dir" validate 2>/dev/null; then
                log_warn "Terraform validation skipped (may need init): $tf_dir"
            fi
        fi
    done
}

# Check for secrets in files
check_for_secrets() {
    log_info "Checking for potential secrets..."

    local patterns=(
        "password.*=.*['\"]"
        "secret.*=.*['\"]"
        "api_key.*=.*['\"]"
        "AWS_ACCESS_KEY"
        "AWS_SECRET"
        "PRIVATE_KEY"
    )

    for pattern in "${patterns[@]}"; do
        if grep -r -l -i "$pattern" --include="*.yaml" --include="*.yml" . 2>/dev/null | grep -v "values.yaml"; then
            log_warn "Potential secret found matching pattern: $pattern"
        fi
    done
}

# Security checks
security_checks() {
    log_info "Running security checks..."

    # Check for privileged containers
    if grep -r "privileged: true" --include="*.yaml" . 2>/dev/null | grep -v "kyverno"; then
        log_warn "Found privileged container definitions"
    fi

    # Check for host network
    if grep -r "hostNetwork: true" --include="*.yaml" . 2>/dev/null; then
        log_warn "Found hostNetwork enabled"
    fi

    # Check for latest tag
    if grep -r "image:.*:latest" --include="*.yaml" . 2>/dev/null; then
        log_warn "Found 'latest' image tags"
    fi
}

# Main
main() {
    log_info "Starting manifest validation..."
    echo ""

    validate_yaml_syntax
    validate_kubernetes_manifests
    validate_kyverno_policies
    validate_helm_charts
    validate_terraform
    check_for_secrets
    security_checks

    echo ""
    echo "=========================================="
    echo " Validation Complete"
    echo "=========================================="
    echo " Errors: $ERRORS"
    echo " Warnings: $WARNINGS"
    echo "=========================================="

    if [ $ERRORS -gt 0 ]; then
        log_error "Validation failed with $ERRORS errors"
        exit 1
    fi

    log_info "All validations passed!"
}

main "$@"
