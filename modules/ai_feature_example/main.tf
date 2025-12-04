# -----------------------------------------------------------------------------
# AI Feature Example Module
# -----------------------------------------------------------------------------
# This module demonstrates how to compose core modules (project_apis, iam,
# secret_manager, cloud_run_service) into a complete feature deployment.
#
# PATTERN: Copy this module when creating new AI features/services.
# 1. Copy this folder to modules/your_new_feature/
# 2. Modify the required APIs, secrets, IAM roles, and Cloud Run config
# 3. Wire it up in envs/dev/main.tf and envs/prod/main.tf
# -----------------------------------------------------------------------------

locals {
  # Feature-specific labels merged with common labels
  feature_labels = merge(var.labels, {
    feature = var.feature_name
  })

  # Service account email (use provided or construct from service_account_id)
  service_account_email = var.service_account_email != null ? var.service_account_email : (
    var.create_service_account ? "${var.service_account_id}@${var.project_id}.iam.gserviceaccount.com" : null
  )
}

# -----------------------------------------------------------------------------
# APIs Required for this Feature
# -----------------------------------------------------------------------------
# Enable any APIs that this feature specifically needs beyond the baseline.
# Common APIs (run, iam, secretmanager) are typically enabled at the env level.
# -----------------------------------------------------------------------------

module "feature_apis" {
  source = "../project_apis"

  count = length(var.additional_apis) > 0 ? 1 : 0

  project_id = var.project_id
  apis       = var.additional_apis
}

# -----------------------------------------------------------------------------
# Service Account for the Feature
# -----------------------------------------------------------------------------
# Create a dedicated service account for this feature's Cloud Run service.
# This follows the principle of least privilege.
# -----------------------------------------------------------------------------

module "feature_iam" {
  source = "../iam"

  project_id = var.project_id

  # Create service account if requested
  service_accounts = var.create_service_account ? {
    (var.service_account_id) = {
      display_name = "${var.feature_name} Service Account"
      description  = "Service account for ${var.feature_name} Cloud Run service"
    }
  } : {}

  # IAM bindings for the feature's service account
  bindings = var.create_service_account ? {
    # Allow SA to write logs
    "roles/logging.logWriter" = [
      "serviceAccount:${var.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
    ]
    # Allow SA to access secrets
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${var.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
    ]
    # Allow SA to report errors
    "roles/errorreporting.writer" = [
      "serviceAccount:${var.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
    ]
  } : {}
}

# -----------------------------------------------------------------------------
# Secrets for the Feature
# -----------------------------------------------------------------------------
# Create secrets specific to this feature (e.g., API keys, credentials).
# Note: The actual secret values can be populated via tfvars (dev) or manually (prod).
# -----------------------------------------------------------------------------

module "feature_secrets" {
  source = "../secret_manager"

  count = length(var.secrets) > 0 ? 1 : 0

  project_id      = var.project_id
  secrets         = var.secrets
  create_versions = var.create_secret_versions
  labels          = local.feature_labels
}

# -----------------------------------------------------------------------------
# Cloud Run Service
# -----------------------------------------------------------------------------
# Deploy the Cloud Run service for this feature.
# -----------------------------------------------------------------------------

module "cloud_run_service" {
  source = "../cloud_run_service"

  service_name    = var.service_name
  project_id      = var.project_id
  region          = var.region
  container_image = var.container_image

  # Service account (wait for IAM module if creating)
  service_account_email = local.service_account_email

  # Scaling
  min_instances = var.min_instances
  max_instances = var.max_instances
  concurrency   = var.concurrency

  # Resources
  cpu_limit    = var.cpu_limit
  memory_limit = var.memory_limit

  # Environment variables
  env_vars = var.env_vars

  # Secrets from Secret Manager
  secrets = var.cloud_run_secrets

  # Ingress and authentication
  ingress               = var.ingress
  allow_unauthenticated = var.allow_unauthenticated
  invokers              = var.invokers

  # Labels
  labels = local.feature_labels

  # Health probes
  startup_probe  = var.startup_probe
  liveness_probe = var.liveness_probe

  depends_on = [
    module.feature_iam,
    module.feature_secrets
  ]
}
