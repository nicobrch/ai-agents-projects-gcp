# -----------------------------------------------------------------------------
# Main Terraform Configuration - Production Environment
# -----------------------------------------------------------------------------
# This file orchestrates the deployment of all infrastructure for the prod
# environment using the reusable modules.
#
# IMPORTANT: Production deployments should be reviewed carefully.
# Always run `terraform plan` and review changes before `terraform apply`.
#
# To add a new feature:
# 1. Create a new module in modules/ (or copy ai_feature_example)
# 2. Add variables in variables.tf
# 3. Add module block below
# 4. Add outputs in outputs.tf
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Centralized values used throughout the configuration.
# -----------------------------------------------------------------------------

locals {
  env_name = var.env_name

  # Common labels applied to all resources
  common_labels = merge({
    env        = local.env_name
    project    = "ai-agents"
    managed_by = "terraform"
    owner      = var.owner
  }, var.additional_labels)

  # APIs to enable (conditionally include AI APIs)
  all_apis = var.enable_ai_apis ? concat(var.enabled_apis, var.ai_apis) : var.enabled_apis
}

# -----------------------------------------------------------------------------
# Enable Required GCP APIs
# -----------------------------------------------------------------------------
# This is typically done first as other resources depend on APIs being enabled.
# -----------------------------------------------------------------------------

module "project_apis" {
  source = "../../modules/project_apis"

  project_id = var.project_id
  apis       = local.all_apis
}

# -----------------------------------------------------------------------------
# Secret Manager - Environment-Level Secrets
# -----------------------------------------------------------------------------
# Create secrets that are shared across multiple services in this environment.
# Feature-specific secrets can be managed within feature modules.
#
# NOTE: For production, create_secret_versions should be false.
# Populate secret values manually or via a secure CI/CD pipeline.
# -----------------------------------------------------------------------------

module "secrets" {
  source = "../../modules/secret_manager"

  project_id      = var.project_id
  secrets         = var.secrets
  create_versions = var.create_secret_versions
  labels          = local.common_labels

  depends_on = [module.project_apis]
}

# -----------------------------------------------------------------------------
# IAM - Environment-Level Bindings
# -----------------------------------------------------------------------------
# Create service accounts and IAM bindings that are shared across the environment.
# Feature-specific IAM is managed within feature modules.
# -----------------------------------------------------------------------------

module "iam" {
  source = "../../modules/iam"

  project_id       = var.project_id
  service_accounts = var.service_accounts
  bindings         = var.iam_bindings

  depends_on = [module.project_apis]
}

# -----------------------------------------------------------------------------
# Artifact Registry for Luca Container Images
# -----------------------------------------------------------------------------
# Docker repository for storing Luca API container images.
# -----------------------------------------------------------------------------

resource "google_artifact_registry_repository" "luca" {
  count = var.luca_enabled ? 1 : 0

  location      = var.region
  repository_id = "luca"
  description   = "Docker repository for Luca API container images"
  format        = "DOCKER"
  project       = var.project_id

  labels = local.common_labels

  depends_on = [module.project_apis]
}

# -----------------------------------------------------------------------------
# Luca API Feature
# -----------------------------------------------------------------------------
# Production deployment of Luca - an AI assistant powered by Google ADK and Gemini.
# Configured for higher availability and performance.
# -----------------------------------------------------------------------------

module "luca_api" {
  source = "../../modules/ai_feature_example"

  count = var.luca_enabled ? 1 : 0

  # Feature identification
  feature_name = "luca-api"
  service_name = "luca-api-${local.env_name}"

  # GCP configuration
  project_id = var.project_id
  region     = var.region

  # Container configuration
  container_image = var.luca_image

  # Service account
  create_service_account = true
  service_account_id     = "luca-cloudrun-sa"

  # Scaling configuration (higher for production)
  min_instances = var.luca_min_instances
  max_instances = var.luca_max_instances
  concurrency   = var.luca_concurrency

  # Resource limits (higher for production)
  cpu_limit    = var.luca_cpu
  memory_limit = var.luca_memory

  # Environment variables
  env_vars = merge(var.luca_env_vars, {
    ENV = local.env_name
  })

  # Secrets from Secret Manager
  cloud_run_secrets = var.luca_secrets

  # Authentication (typically more restrictive in prod)
  allow_unauthenticated = var.luca_allow_unauthenticated
  invokers              = var.luca_invokers

  # Labels
  labels = local.common_labels

  # Health check
  startup_probe = {
    http_get = {
      path = "/health"
    }
    initial_delay_seconds = 0
    period_seconds        = 3
    failure_threshold     = 3
  }

  liveness_probe = {
    http_get = {
      path = "/health"
    }
    period_seconds    = 30
    failure_threshold = 3
  }

  depends_on = [
    module.project_apis,
    module.secrets,
    module.iam,
    google_artifact_registry_repository.luca
  ]
}

# -----------------------------------------------------------------------------
# GitHub CI/CD Service Account for Luca
# -----------------------------------------------------------------------------
# Dedicated service account for GitHub Actions to push images to Artifact
# Registry and deploy to Cloud Run.
# -----------------------------------------------------------------------------

resource "google_service_account" "luca_github_ci" {
  count = var.luca_enabled ? 1 : 0

  project      = var.project_id
  account_id   = "luca-github-ci-sa"
  display_name = "Luca GitHub CI/CD Service Account"
  description  = "Service account for GitHub Actions to build and deploy Luca"
}

# Grant CI/CD SA permission to push to Artifact Registry
resource "google_artifact_registry_repository_iam_member" "luca_github_ci_writer" {
  count = var.luca_enabled ? 1 : 0

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.luca[0].name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.luca_github_ci[0].email}"
}

# Grant CI/CD SA permission to deploy Cloud Run services
resource "google_project_iam_member" "luca_github_ci_run_admin" {
  count = var.luca_enabled ? 1 : 0

  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.luca_github_ci[0].email}"
}

# Grant CI/CD SA permission to act as the Cloud Run service account
resource "google_service_account_iam_member" "luca_github_ci_sa_user" {
  count = var.luca_enabled ? 1 : 0

  service_account_id = "projects/${var.project_id}/serviceAccounts/luca-cloudrun-sa@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.luca_github_ci[0].email}"

  depends_on = [module.luca_api]
}

# Allow GitHub Actions to impersonate the Luca CI/CD service account via Workload Identity Federation
resource "google_service_account_iam_member" "luca_github_ci_wif" {
  count = var.luca_enabled && var.luca_github_repo != "" ? 1 : 0

  service_account_id = google_service_account.luca_github_ci[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/attribute.repository/${var.luca_github_repo}"
}

# -----------------------------------------------------------------------------
# ADD NEW FEATURES HERE
# -----------------------------------------------------------------------------
# Copy the luca_api module block above and modify for your new feature.
# Remember to configure production-appropriate settings:
# - Higher min_instances for availability
# - Appropriate max_instances for cost/performance balance
# - Stricter authentication (allow_unauthenticated = false)
# - Production log levels
# -----------------------------------------------------------------------------
