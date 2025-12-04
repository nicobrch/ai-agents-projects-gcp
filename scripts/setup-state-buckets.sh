#!/bin/bash
# -----------------------------------------------------------------------------
# Setup Script - Create Terraform State Buckets
# -----------------------------------------------------------------------------
# This script creates the GCS buckets needed for Terraform state storage.
# Run this once before initializing Terraform.
#
# Prerequisites:
# - gcloud CLI installed and authenticated
# - Appropriate permissions to create GCS buckets
# -----------------------------------------------------------------------------

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Configuration
DEV_PROJECT="dev-ai-agents-projects"
PROD_PROJECT="prod-ai-agents-projects"
LOCATION="us-central1"

DEV_BUCKET="gs://${DEV_PROJECT}-tfstate"
PROD_BUCKET="gs://${PROD_PROJECT}-tfstate"

create_state_bucket() {
    local project="$1"
    local bucket="$2"

    print_info "Creating state bucket $bucket in project $project..."

    # Check if bucket exists
    if gcloud storage buckets describe "$bucket" --project="$project" &>/dev/null; then
        print_warning "Bucket $bucket already exists"
    else
        # Create bucket
        gcloud storage buckets create "$bucket" \
            --project="$project" \
            --location="$LOCATION" \
            --uniform-bucket-level-access

        print_success "Created bucket $bucket"
    fi

    # Enable versioning
    print_info "Enabling versioning on $bucket..."
    gcloud storage buckets update "$bucket" --versioning
    print_success "Versioning enabled on $bucket"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

echo "=========================================="
echo "Terraform State Bucket Setup"
echo "=========================================="
echo ""

print_info "This script will create GCS buckets for Terraform state storage."
echo ""

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &>/dev/null; then
    print_error "gcloud is not authenticated. Run 'gcloud auth login' first."
    exit 1
fi

ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
print_info "Using gcloud account: $ACTIVE_ACCOUNT"
echo ""

read -p "Create state buckets for dev and prod? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    print_info "Creating development state bucket..."
    create_state_bucket "$DEV_PROJECT" "$DEV_BUCKET"

    echo ""
    print_info "Creating production state bucket..."
    create_state_bucket "$PROD_PROJECT" "$PROD_BUCKET"

    echo ""
    print_success "State buckets setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. cd envs/dev && cp terraform.tfvars.example terraform.tfvars"
    echo "  2. Edit terraform.tfvars with your values"
    echo "  3. terraform init"
    echo "  4. terraform plan"
else
    print_info "Aborted."
fi
