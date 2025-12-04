# -----------------------------------------------------------------------------
# Project APIs Module
# -----------------------------------------------------------------------------
# This module enables GCP APIs/services for a given project.
# It uses google_project_service with disable_on_destroy = false by default
# to prevent accidental service disruption when resources are removed.
# -----------------------------------------------------------------------------

resource "google_project_service" "apis" {
  for_each = toset(var.apis)

  project = var.project_id
  service = each.value

  # Prevents the API from being disabled when this resource is destroyed.
  # This is safer for production as other resources may depend on the API.
  disable_on_destroy = var.disable_on_destroy

  # Disable dependent services when disabling a service.
  # Only relevant if disable_on_destroy = true.
  disable_dependent_services = var.disable_dependent_services

  timeouts {
    create = var.timeout_create
    update = var.timeout_update
  }
}
