# -----------------------------------------------------------------------------
# IAM Module - Outputs
# -----------------------------------------------------------------------------

output "service_accounts" {
  description = "Map of created service accounts"
  value = {
    for k, v in google_service_account.service_accounts : k => {
      email      = v.email
      name       = v.name
      unique_id  = v.unique_id
      account_id = v.account_id
    }
  }
}

output "service_account_emails" {
  description = "Map of service account names to their email addresses"
  value = {
    for k, v in google_service_account.service_accounts : k => v.email
  }
}

output "bindings" {
  description = "Map of IAM bindings created"
  value = {
    for k, v in google_project_iam_member.bindings : k => {
      role   = v.role
      member = v.member
    }
  }
}
