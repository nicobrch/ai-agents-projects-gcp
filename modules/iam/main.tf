# -----------------------------------------------------------------------------
# IAM Module
# -----------------------------------------------------------------------------
# This module manages IAM bindings at the project level.
# It uses google_project_iam_member for additive-only bindings (safe approach).
#
# IMPORTANT: This module does NOT replace the entire IAM policy. It only adds
# the specified bindings, making it safe to use alongside other IAM management.
# -----------------------------------------------------------------------------

locals {
  # Flatten bindings map into a list of role-member pairs
  # Input: { "roles/run.invoker" = ["serviceAccount:sa@proj.iam.gserviceaccount.com"] }
  # Output: [{ role = "roles/run.invoker", member = "serviceAccount:sa@..." }]
  iam_bindings_flat = flatten([
    for role, members in var.bindings : [
      for member in members : {
        role   = role
        member = member
      }
    ]
  ])

  # Create unique keys for each binding
  iam_bindings_map = {
    for binding in local.iam_bindings_flat :
    "${binding.role}|${binding.member}" => binding
  }
}

# -----------------------------------------------------------------------------
# Service Accounts
# -----------------------------------------------------------------------------
# Optionally create service accounts that can be referenced in bindings.
# This is useful for Cloud Run and other services that need dedicated SAs.
# -----------------------------------------------------------------------------

resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  project      = var.project_id
  account_id   = each.key
  display_name = try(each.value.display_name, each.key)
  description  = try(each.value.description, "Service account managed by Terraform")
}

# -----------------------------------------------------------------------------
# Project IAM Member Bindings
# -----------------------------------------------------------------------------
# Uses google_project_iam_member which is additive and safe.
# Each binding is independent and won't affect other bindings.
# -----------------------------------------------------------------------------

resource "google_project_iam_member" "bindings" {
  for_each = local.iam_bindings_map

  project = var.project_id
  role    = each.value.role
  member  = each.value.member

  # Allow referencing service accounts created in this module
  depends_on = [google_service_account.service_accounts]
}

# -----------------------------------------------------------------------------
# Service Account IAM (allow impersonation)
# -----------------------------------------------------------------------------
# Optionally grant users/groups the ability to impersonate service accounts.
# -----------------------------------------------------------------------------

resource "google_service_account_iam_member" "impersonation" {
  for_each = var.service_account_impersonation

  service_account_id = try(
    google_service_account.service_accounts[each.value.service_account].name,
    "projects/${var.project_id}/serviceAccounts/${each.value.service_account}"
  )
  role   = "roles/iam.serviceAccountUser"
  member = each.value.member
}
