# -----------------------------------------------------------------------------
# Cloud Run V2 Service Module - Outputs
# -----------------------------------------------------------------------------

output "service_id" {
  description = "The unique identifier of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.id
}

output "service_name" {
  description = "The name of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.name
}

output "service_url" {
  description = "The URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.uri
}

output "service_location" {
  description = "The location/region of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.location
}

output "latest_revision" {
  description = "The name of the latest revision"
  value       = google_cloud_run_v2_service.service.latest_ready_revision
}

output "service_account" {
  description = "The service account used by the Cloud Run service"
  value       = var.service_account_email
}

output "service" {
  description = "The full Cloud Run service resource"
  value       = google_cloud_run_v2_service.service
}
