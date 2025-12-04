# -----------------------------------------------------------------------------
# Outputs - Development Environment
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project Information
# -----------------------------------------------------------------------------

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "environment" {
  description = "Environment name"
  value       = local.env_name
}

# -----------------------------------------------------------------------------
# Enabled APIs
# -----------------------------------------------------------------------------

output "enabled_apis" {
  description = "List of enabled GCP APIs"
  value       = module.project_apis.enabled_apis
}

# -----------------------------------------------------------------------------
# Secrets
# -----------------------------------------------------------------------------

output "secret_ids" {
  description = "Map of secret names to their resource IDs"
  value       = module.secrets.secret_ids
}

output "secret_names" {
  description = "Map of secret names to their full resource names"
  value       = module.secrets.secret_names
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------

output "service_account_emails" {
  description = "Map of service account names to emails"
  value       = module.iam.service_account_emails
}

# -----------------------------------------------------------------------------
# Luca API
# -----------------------------------------------------------------------------

output "luca_api_url" {
  description = "URL of the Luca API Cloud Run service"
  value       = var.luca_enabled ? module.luca_api[0].service_url : null
}

output "luca_api_service_name" {
  description = "Name of the Luca API Cloud Run service"
  value       = var.luca_enabled ? module.luca_api[0].service_name : null
}

output "luca_cloudrun_service_account" {
  description = "Service account email used by Luca API Cloud Run"
  value       = var.luca_enabled ? module.luca_api[0].service_account_email : null
}

output "luca_github_ci_service_account" {
  description = "Service account email for GitHub Actions CI/CD"
  value       = var.luca_enabled ? google_service_account.luca_github_ci[0].email : null
}

output "luca_artifact_registry_repo" {
  description = "Artifact Registry repository name for Luca container images"
  value       = var.luca_enabled ? google_artifact_registry_repository.luca[0].name : null
}

output "luca_artifact_registry_path" {
  description = "Full path to push Docker images (REGION-docker.pkg.dev/PROJECT/REPO)"
  value       = var.luca_enabled ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.luca[0].name}" : null
}

output "luca_workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions (use as GCP_WORKLOAD_IDENTITY_PROVIDER_DEV secret)"
  value       = var.luca_enabled && var.luca_github_repo != "" ? "projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/providers/github-provider" : null
}

# -----------------------------------------------------------------------------
# ADD OUTPUTS FOR NEW FEATURES HERE
# -----------------------------------------------------------------------------
