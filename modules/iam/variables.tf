# -----------------------------------------------------------------------------
# IAM Module - Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID for IAM bindings"
  type        = string
}

variable "bindings" {
  description = <<-EOT
    Map of IAM role to list of members.
    Members should be in the format: "user:email", "serviceAccount:email", "group:email"

    Example:
    {
      "roles/run.invoker" = [
        "serviceAccount:ai-api-sa@project.iam.gserviceaccount.com",
        "user:developer@example.com"
      ]
      "roles/secretmanager.secretAccessor" = [
        "serviceAccount:ai-api-sa@project.iam.gserviceaccount.com"
      ]
    }
  EOT
  type        = map(list(string))
  default     = {}
}

variable "service_accounts" {
  description = <<-EOT
    Map of service accounts to create.
    Key is the account_id (e.g., "ai-api-sa"), value contains optional display_name and description.

    Example:
    {
      "ai-api-sa" = {
        display_name = "AI API Service Account"
        description  = "Service account for AI API Cloud Run service"
      }
    }
  EOT
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
  }))
  default = {}
}

variable "service_account_impersonation" {
  description = <<-EOT
    Map of service account impersonation grants.
    Allows specified members to impersonate (act as) the service account.

    Example:
    {
      "dev-impersonate" = {
        service_account = "ai-api-sa"
        member          = "user:developer@example.com"
      }
    }
  EOT
  type = map(object({
    service_account = string
    member          = string
  }))
  default = {}
}
