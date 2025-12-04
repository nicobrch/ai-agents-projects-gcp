# -----------------------------------------------------------------------------
# Secret Manager Module
# -----------------------------------------------------------------------------
# This module creates Secret Manager secrets and optionally their initial versions.
# Secrets can be referenced by Cloud Run services or other GCP resources.
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = each.key

  labels = merge(var.labels, try(each.value.labels, {}))

  replication {
    dynamic "auto" {
      for_each = try(each.value.replication, "auto") == "auto" ? [1] : []
      content {}
    }

    dynamic "user_managed" {
      for_each = try(each.value.replication, "auto") != "auto" ? [1] : []
      content {
        dynamic "replicas" {
          for_each = try(each.value.replica_locations, [var.default_location])
          content {
            location = replicas.value
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Secret Versions
# -----------------------------------------------------------------------------
# Create initial secret versions only if:
# 1. create_versions is true (module-level)
# 2. The secret has an initial_value defined
#
# NOTE: For production, you may want to skip initial versions and populate
# secrets manually or via CI/CD to avoid storing sensitive values in state.
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret_version" "versions" {
  for_each = var.create_versions ? {
    for k, v in var.secrets : k => v if try(v.initial_value, null) != null
  } : {}

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value.initial_value

  # Lifecycle to prevent accidental destruction of secrets with data
  lifecycle {
    # Set to true if you want to prevent version destruction
    # prevent_destroy = true
  }
}
