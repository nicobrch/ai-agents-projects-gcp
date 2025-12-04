# -----------------------------------------------------------------------------
# AI Feature Example Module - Outputs
# -----------------------------------------------------------------------------

output "service_url" {
  description = "The URL of the Cloud Run service"
  value       = module.cloud_run_service.service_url
}

output "service_name" {
  description = "The name of the Cloud Run service"
  value       = module.cloud_run_service.service_name
}

output "service_id" {
  description = "The unique identifier of the Cloud Run service"
  value       = module.cloud_run_service.service_id
}

output "service_account_email" {
  description = "The service account email used by the Cloud Run service"
  value       = local.service_account_email
}

output "service_account_emails" {
  description = "Map of service accounts created by this module"
  value       = module.feature_iam.service_account_emails
}

output "secret_ids" {
  description = "Map of secret names to their resource IDs"
  value       = length(module.feature_secrets) > 0 ? module.feature_secrets[0].secret_ids : {}
}

output "enabled_apis" {
  description = "List of additional APIs enabled for this feature"
  value       = length(module.feature_apis) > 0 ? module.feature_apis[0].enabled_apis : []
}
