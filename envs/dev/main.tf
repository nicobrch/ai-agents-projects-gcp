# -----------------------------------------------------------------------------
# Main Terraform Configuration - Development Environment
# -----------------------------------------------------------------------------
# This file orchestrates the deployment of all infrastructure for the dev
# environment using the reusable modules.
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

  # Service account email for AI Agents API
  ai_agents_api_sa_email = "ai-agents-api-sa@${var.project_id}.iam.gserviceaccount.com"
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
# AI Agents API Feature
# -----------------------------------------------------------------------------
# Example feature deployment using the ai_feature_example module.
# This demonstrates the pattern for deploying AI services.
#
# To add another feature, copy this block and adjust:
# - Module source (if using a custom feature module)
# - feature_name and service_name
# - Variables from var.new_feature_*
# -----------------------------------------------------------------------------

module "ai_agents_api" {
  source = "../../modules/ai_feature_example"

  count = var.ai_agents_api_enabled ? 1 : 0

  # Feature identification
  feature_name = "ai-agents-api"
  service_name = "ai-agents-api-${local.env_name}"

  # GCP configuration
  project_id = var.project_id
  region     = var.region

  # Container configuration
  container_image = var.ai_agents_api_image

  # Service account
  create_service_account = true
  service_account_id     = "ai-agents-api-sa"

  # Scaling configuration
  min_instances = var.ai_agents_api_min_instances
  max_instances = var.ai_agents_api_max_instances
  concurrency   = var.ai_agents_api_concurrency

  # Resource limits
  cpu_limit    = var.ai_agents_api_cpu
  memory_limit = var.ai_agents_api_memory

  # Environment variables
  env_vars = merge(var.ai_agents_api_env_vars, {
    ENV = local.env_name
  })

  # Secrets (reference secrets created by the secrets module or elsewhere)
  # Uncomment and modify when you have actual secrets:
  # cloud_run_secrets = {
  #   "OPENAI_API_KEY" = {
  #     secret_name = module.secrets.secret_names["openai-api-key"]
  #   }
  # }

  # Authentication
  allow_unauthenticated = var.ai_agents_api_allow_unauthenticated
  invokers              = var.ai_agents_api_invokers

  # Labels
  labels = local.common_labels

  # Health check (optional)
  startup_probe = {
    http_get = {
      path = "/health"
    }
    initial_delay_seconds = 0
    period_seconds        = 3
    failure_threshold     = 3
  }

  depends_on = [
    module.project_apis,
    module.secrets,
    module.iam
  ]
}

# -----------------------------------------------------------------------------
# ADD NEW FEATURES HERE
# -----------------------------------------------------------------------------
# Copy the ai_agents_api module block above and modify for your new feature.
# Example:
#
# module "my_new_feature" {
#   source = "../../modules/ai_feature_example"  # or custom module
#
#   count = var.my_new_feature_enabled ? 1 : 0
#
#   feature_name = "my-new-feature"
#   service_name = "my-new-feature-${local.env_name}"
#   project_id   = var.project_id
#   region       = var.region
#
#   container_image = var.my_new_feature_image
#   # ... other configuration
#
#   depends_on = [module.project_apis]
# }
# -----------------------------------------------------------------------------
