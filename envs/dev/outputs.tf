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
# AI Agents API
# -----------------------------------------------------------------------------

output "ai_agents_api_url" {
  description = "URL of the AI Agents API Cloud Run service"
  value       = var.ai_agents_api_enabled ? module.ai_agents_api[0].service_url : null
}

output "ai_agents_api_service_name" {
  description = "Name of the AI Agents API Cloud Run service"
  value       = var.ai_agents_api_enabled ? module.ai_agents_api[0].service_name : null
}

output "ai_agents_api_service_account" {
  description = "Service account email used by AI Agents API"
  value       = var.ai_agents_api_enabled ? module.ai_agents_api[0].service_account_email : null
}

# -----------------------------------------------------------------------------
# ADD OUTPUTS FOR NEW FEATURES HERE
# -----------------------------------------------------------------------------
# Example:
#
# output "my_new_feature_url" {
#   description = "URL of My New Feature service"
#   value       = var.my_new_feature_enabled ? module.my_new_feature[0].service_url : null
# }
# -----------------------------------------------------------------------------
