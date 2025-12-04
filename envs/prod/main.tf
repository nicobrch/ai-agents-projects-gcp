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
# AI Agents API Feature
# -----------------------------------------------------------------------------
# Production deployment of the AI Agents API.
# Configured for higher availability and performance.
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

  # Scaling configuration (higher for production)
  min_instances = var.ai_agents_api_min_instances
  max_instances = var.ai_agents_api_max_instances
  concurrency   = var.ai_agents_api_concurrency

  # Resource limits (higher for production)
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

  # Authentication (typically more restrictive in prod)
  allow_unauthenticated = var.ai_agents_api_allow_unauthenticated
  invokers              = var.ai_agents_api_invokers

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
    module.iam
  ]
}

# -----------------------------------------------------------------------------
# ADD NEW FEATURES HERE
# -----------------------------------------------------------------------------
# Copy the ai_agents_api module block above and modify for your new feature.
# Remember to configure production-appropriate settings:
# - Higher min_instances for availability
# - Appropriate max_instances for cost/performance balance
# - Stricter authentication (allow_unauthenticated = false)
# - Production log levels
# -----------------------------------------------------------------------------
