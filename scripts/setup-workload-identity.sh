#!/bin/bash
# ============================================================================
# Setup Workload Identity Federation for GitHub Actions
# ============================================================================
# This script creates:
#   1. A Workload Identity Pool for GitHub Actions
#   2. An OIDC Provider within the pool
#   3. A Service Account for Terraform
#   4. IAM bindings to allow GitHub Actions to impersonate the SA
#
# Usage:
#   ./setup-workload-identity.sh <PROJECT_ID> <PROJECT_NUMBER> [GITHUB_REPO]
#
# Examples:
#   ./setup-workload-identity.sh dev-ai-agents-projects 100423676481
#   ./setup-workload-identity.sh prod-ai-agents-projects 987654321 myorg/myrepo
#
# Prerequisites:
#   - gcloud CLI installed and authenticated
#   - Appropriate permissions on the GCP project (Owner or IAM Admin)
#   - IAM Credentials API enabled on the project
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Configuration
# ============================================================================
# These can be customized if needed
POOL_ID="github-pool"
POOL_DISPLAY_NAME="GitHub Actions Pool"
PROVIDER_ID="github-provider"
PROVIDER_DISPLAY_NAME="GitHub Provider"
SERVICE_ACCOUNT_NAME="github-terraform"
SERVICE_ACCOUNT_DISPLAY_NAME="GitHub Terraform SA"
# Default GitHub repository (owner/repo format)
DEFAULT_GITHUB_REPO="nicobrch/ai-agents-projects-gcp"

# ============================================================================
# Argument Parsing
# ============================================================================
usage() {
    echo -e "${BLUE}Usage:${NC} $0 <PROJECT_ID> <PROJECT_NUMBER> [GITHUB_REPO]"
    echo ""
    echo "Arguments:"
    echo "  PROJECT_ID      GCP Project ID (e.g., dev-ai-agents-projects)"
    echo "  PROJECT_NUMBER  GCP Project Number (e.g., 100423676481)"
    echo "  GITHUB_REPO     GitHub repository in owner/repo format (default: ${DEFAULT_GITHUB_REPO})"
    echo ""
    echo "Examples:"
    echo "  $0 dev-ai-agents-projects 100423676481"
    echo "  $0 prod-ai-agents-projects 987654321 myorg/myrepo"
    echo ""
    echo "To find your project number, run:"
    echo "  gcloud projects describe <PROJECT_ID> --format='value(projectNumber)'"
    exit 1
}

if [[ $# -lt 2 ]]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    usage
fi

PROJECT_ID="$1"
PROJECT_NUMBER="$2"
GITHUB_REPO="${3:-$DEFAULT_GITHUB_REPO}"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Setting up Workload Identity Federation${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "Project ID:     ${GREEN}${PROJECT_ID}${NC}"
echo -e "Project Number: ${GREEN}${PROJECT_NUMBER}${NC}"
echo -e "GitHub Repo:    ${GREEN}${GITHUB_REPO}${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# Step 0: Enable required APIs
# ============================================================================
echo -e "${YELLOW}[Step 0/6]${NC} Enabling required APIs..."
gcloud services enable iamcredentials.googleapis.com --project="${PROJECT_ID}"
gcloud services enable iam.googleapis.com --project="${PROJECT_ID}"
echo -e "${GREEN}✓ APIs enabled${NC}"
echo ""

# Optional: Set default project for remaining commands
# This prevents errors if gcloud default project differs
gcloud config set project "${PROJECT_ID}"
echo -e "${GREEN}✓ Set gcloud default project to ${PROJECT_ID}${NC}"
echo ""

# ============================================================================
# Step 1: Create Workload Identity Pool
# ============================================================================
echo -e "${YELLOW}[Step 1/6]${NC} Creating Workload Identity Pool..."

# Check if pool already exists
if gcloud iam workload-identity-pools describe "${POOL_ID}" \
    --project="${PROJECT_ID}" \
    --location="global" &>/dev/null; then
    echo -e "${YELLOW}⚠ Pool '${POOL_ID}' already exists, skipping creation${NC}"
else
    gcloud iam workload-identity-pools create "${POOL_ID}" \
        --project="${PROJECT_ID}" \
        --location="global" \
        --display-name="${POOL_DISPLAY_NAME}"
    echo -e "${GREEN}✓ Workload Identity Pool created${NC}"
fi
echo ""

# ============================================================================
# Step 2: Get Pool Resource Name
# ============================================================================
echo -e "${YELLOW}[Step 2/6]${NC} Getting Pool resource name..."
POOL_NAME=$(gcloud iam workload-identity-pools describe "${POOL_ID}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --format="value(name)")
echo -e "Pool Name: ${GREEN}${POOL_NAME}${NC}"
echo ""

# ============================================================================
# Step 3: Create OIDC Provider
# ============================================================================
echo -e "${YELLOW}[Step 3/6]${NC} Creating OIDC Provider..."

# Check if provider already exists
if gcloud iam workload-identity-pools providers describe "${PROVIDER_ID}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="${POOL_ID}" &>/dev/null; then
    echo -e "${YELLOW}⚠ Provider '${PROVIDER_ID}' already exists, skipping creation${NC}"
else
    gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_ID}" \
        --project="${PROJECT_ID}" \
        --location="global" \
        --workload-identity-pool="${POOL_ID}" \
        --display-name="${PROVIDER_DISPLAY_NAME}" \
        --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
        --attribute-condition="attribute.repository=='${GITHUB_REPO}'" \
        --issuer-uri="https://token.actions.githubusercontent.com"
    echo -e "${GREEN}✓ OIDC Provider created${NC}"
fi
echo ""

# ============================================================================
# Step 4: Create Service Account
# ============================================================================
echo -e "${YELLOW}[Step 4/6]${NC} Creating Service Account..."
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if service account already exists
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT_EMAIL}" \
    --project="${PROJECT_ID}" &>/dev/null; then
    echo -e "${YELLOW}⚠ Service Account '${SERVICE_ACCOUNT_EMAIL}' already exists, skipping creation${NC}"
else
    gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
        --project="${PROJECT_ID}" \
        --display-name="${SERVICE_ACCOUNT_DISPLAY_NAME}"
    echo -e "${GREEN}✓ Service Account created${NC}"
fi
echo ""

# ============================================================================
# Step 5: Grant IAM Roles to Service Account
# ============================================================================
echo -e "${YELLOW}[Step 5/6]${NC} Granting IAM roles to Service Account..."

# Grant Editor role for general resource management
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/editor" \
    --condition=None \
    --quiet

echo -e "${GREEN}✓ Editor role granted${NC}"

# Grant Project IAM Admin role for managing IAM policies
# Required for Terraform to assign roles to service accounts
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/resourcemanager.projectIamAdmin" \
    --condition=None \
    --quiet

echo -e "${GREEN}✓ Project IAM Admin role granted${NC}"
echo ""

# ============================================================================
# Step 6: Allow GitHub Actions to Impersonate Service Account
# ============================================================================
echo -e "${YELLOW}[Step 6/6]${NC} Configuring Workload Identity User binding..."

MEMBER="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_REPO}"

gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_EMAIL}" \
    --project="${PROJECT_ID}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="${MEMBER}"

echo -e "${GREEN}✓ Workload Identity User binding configured${NC}"
echo ""

# ============================================================================
# Get Provider Resource Name for GitHub Secrets
# ============================================================================
PROVIDER_NAME=$(gcloud iam workload-identity-pools providers describe "${PROVIDER_ID}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="${POOL_ID}" \
    --format="value(name)")

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${YELLOW}GitHub Secrets to configure:${NC}"
echo ""
echo -e "For ${GREEN}${PROJECT_ID}${NC} environment, add these secrets to your GitHub repository:"
echo ""
echo -e "  ${BLUE}GCP_WORKLOAD_IDENTITY_PROVIDER${NC} (or environment-specific name):"
echo -e "  ${GREEN}${PROVIDER_NAME}${NC}"
echo ""
echo -e "  ${BLUE}GCP_SERVICE_ACCOUNT_EMAIL${NC} (or environment-specific name):"
echo -e "  ${GREEN}${SERVICE_ACCOUNT_EMAIL}${NC}"
echo ""
echo -e "${YELLOW}Suggested secret naming for multi-environment setup:${NC}"
echo ""
if [[ "${PROJECT_ID}" == *"dev"* ]]; then
    echo -e "  DEV_GCP_WORKLOAD_IDENTITY_PROVIDER"
    echo -e "  DEV_GCP_SERVICE_ACCOUNT_EMAIL"
elif [[ "${PROJECT_ID}" == *"prod"* ]]; then
    echo -e "  PROD_GCP_WORKLOAD_IDENTITY_PROVIDER"
    echo -e "  PROD_GCP_SERVICE_ACCOUNT_EMAIL"
else
    echo -e "  <ENV>_GCP_WORKLOAD_IDENTITY_PROVIDER"
    echo -e "  <ENV>_GCP_SERVICE_ACCOUNT_EMAIL"
fi
echo ""
echo -e "${BLUE}============================================================================${NC}"
