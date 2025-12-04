# -----------------------------------------------------------------------------
# Secret Manager Module - Outputs
# -----------------------------------------------------------------------------

output "secret_ids" {
  description = "Map of secret names to their full resource IDs"
  value = {
    for k, v in google_secret_manager_secret.secrets : k => v.id
  }
}

output "secret_names" {
  description = "Map of secret names to their resource names (projects/PROJECT/secrets/SECRET)"
  value = {
    for k, v in google_secret_manager_secret.secrets : k => v.name
  }
}

output "secrets" {
  description = "Full secret resource objects for reference"
  value       = google_secret_manager_secret.secrets
}

output "secret_version_ids" {
  description = "Map of secret names to their latest version IDs (only for secrets with initial_value)"
  value = {
    for k, v in google_secret_manager_secret_version.versions : k => v.id
  }
}
