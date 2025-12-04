# -----------------------------------------------------------------------------
# Secret Manager Module - Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID where secrets will be created"
  type        = string
}

variable "secrets" {
  description = <<-EOT
    Map of secrets to create. Each secret can have:
    - replication: "auto" (default) or "user_managed"
    - replica_locations: list of regions (only for user_managed replication)
    - initial_value: optional initial secret value (for dev/test environments)
    - labels: optional map of labels specific to this secret

    Example:
    {
      "api-key" = {
        replication   = "auto"
        initial_value = "my-dev-api-key"
        labels        = { service = "ai-api" }
      }
      "db-password" = {
        replication       = "user_managed"
        replica_locations = ["us-central1", "us-east1"]
      }
    }
  EOT
  type = map(object({
    replication       = optional(string, "auto")
    replica_locations = optional(list(string))
    initial_value     = optional(string)
    labels            = optional(map(string), {})
  }))
  default = {}
}

variable "create_versions" {
  description = "Whether to create initial secret versions. Set to false in production to manage secrets externally."
  type        = bool
  default     = true
}

variable "default_location" {
  description = "Default location for user_managed replication if not specified per-secret"
  type        = string
  default     = "us-central1"
}

variable "labels" {
  description = "Labels to apply to all secrets (merged with per-secret labels)"
  type        = map(string)
  default     = {}
}
