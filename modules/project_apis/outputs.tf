# -----------------------------------------------------------------------------
# Project APIs Module - Outputs
# -----------------------------------------------------------------------------

output "enabled_apis" {
  description = "List of APIs that have been enabled"
  value       = [for api in google_project_service.apis : api.service]
}

output "enabled_apis_map" {
  description = "Map of enabled APIs with their details"
  value = {
    for api in google_project_service.apis : api.service => {
      project = api.project
      service = api.service
    }
  }
}
