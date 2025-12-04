#!/bin/bash
# -----------------------------------------------------------------------------
# Terraform Helper Script
# -----------------------------------------------------------------------------
# Usage: ./scripts/tf.sh <environment> <command> [options]
#
# Examples:
#   ./scripts/tf.sh dev init
#   ./scripts/tf.sh dev plan
#   ./scripts/tf.sh dev apply
#   ./scripts/tf.sh prod plan
#   ./scripts/tf.sh all fmt
#   ./scripts/tf.sh all validate
# -----------------------------------------------------------------------------

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

print_usage() {
    echo "Usage: $0 <environment> <command> [options]"
    echo ""
    echo "Environments:"
    echo "  dev     - Development environment"
    echo "  prod    - Production environment"
    echo "  all     - All environments (for fmt, validate)"
    echo ""
    echo "Commands:"
    echo "  init      - Initialize Terraform"
    echo "  plan      - Plan changes"
    echo "  apply     - Apply changes"
    echo "  destroy   - Destroy infrastructure"
    echo "  fmt       - Format Terraform files"
    echo "  validate  - Validate configuration"
    echo "  output    - Show outputs"
    echo ""
    echo "Options:"
    echo "  -auto-approve   - Auto-approve applies/destroys"
    echo ""
    echo "Examples:"
    echo "  $0 dev init"
    echo "  $0 dev plan"
    echo "  $0 dev apply"
    echo "  $0 prod plan"
    echo "  $0 all fmt"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_tfvars() {
    local env_dir="$1"
    if [[ ! -f "$env_dir/terraform.tfvars" ]]; then
        print_warning "terraform.tfvars not found in $env_dir"
        print_info "Copy terraform.tfvars.example to terraform.tfvars and customize values"
        return 1
    fi
    return 0
}

run_terraform() {
    local env="$1"
    local command="$2"
    shift 2
    local options="$@"

    local env_dir="$ROOT_DIR/envs/$env"

    if [[ ! -d "$env_dir" ]]; then
        print_error "Environment directory not found: $env_dir"
        exit 1
    fi

    print_info "Running 'terraform $command' in $env environment..."

    cd "$env_dir"

    case "$command" in
        init)
            terraform init $options
            ;;
        plan)
            if check_tfvars "$env_dir"; then
                terraform plan -var-file="terraform.tfvars" $options
            else
                terraform plan $options
            fi
            ;;
        apply)
            if check_tfvars "$env_dir"; then
                terraform apply -var-file="terraform.tfvars" $options
            else
                terraform apply $options
            fi
            ;;
        destroy)
            if check_tfvars "$env_dir"; then
                terraform destroy -var-file="terraform.tfvars" $options
            else
                terraform destroy $options
            fi
            ;;
        output)
            terraform output $options
            ;;
        validate)
            terraform validate $options
            ;;
        fmt)
            terraform fmt -recursive $options
            ;;
        *)
            terraform $command $options
            ;;
    esac

    print_success "Completed 'terraform $command' in $env environment"
}

run_all() {
    local command="$1"
    shift
    local options="$@"

    print_info "Running 'terraform $command' across all environments..."

    case "$command" in
        fmt)
            print_info "Formatting all Terraform files..."
            cd "$ROOT_DIR"
            terraform fmt -recursive
            print_success "Formatting complete"
            ;;
        validate)
            for env in dev prod; do
                print_info "Validating $env environment..."
                cd "$ROOT_DIR/envs/$env"
                terraform validate
            done
            print_success "Validation complete for all environments"
            ;;
        *)
            print_error "Command '$command' is not supported with 'all' environment"
            print_info "Supported commands for 'all': fmt, validate"
            exit 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

if [[ $# -lt 2 ]]; then
    print_usage
    exit 1
fi

ENV="$1"
COMMAND="$2"
shift 2
OPTIONS="$@"

case "$ENV" in
    dev|prod)
        run_terraform "$ENV" "$COMMAND" $OPTIONS
        ;;
    all)
        run_all "$COMMAND" $OPTIONS
        ;;
    *)
        print_error "Unknown environment: $ENV"
        print_usage
        exit 1
        ;;
esac
