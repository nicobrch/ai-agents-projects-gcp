# -----------------------------------------------------------------------------
# AI Feature Example Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "feature_name" {
  description = "Name of the feature (used for labels and descriptions)"
  type        = string
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for deployment"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

# -----------------------------------------------------------------------------
# Service Account Configuration
# -----------------------------------------------------------------------------

variable "create_service_account" {
  description = "Whether to create a dedicated service account for this feature"
  type        = bool
  default     = true
}

variable "service_account_id" {
  description = "Service account ID to create (if create_service_account is true)"
  type        = string
  default     = null
}

variable "service_account_email" {
  description = "Existing service account email (if not creating one)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# APIs
# -----------------------------------------------------------------------------

variable "additional_apis" {
  description = "Additional APIs to enable for this feature (beyond common APIs)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Secrets Configuration
# -----------------------------------------------------------------------------

variable "secrets" {
  description = "Map of secrets to create for this feature"
  type = map(object({
    replication       = optional(string, "auto")
    replica_locations = optional(list(string))
    initial_value     = optional(string)
    labels            = optional(map(string), {})
  }))
  default = {}
}

variable "create_secret_versions" {
  description = "Whether to create initial secret versions"
  type        = bool
  default     = true
}

variable "cloud_run_secrets" {
  description = <<-EOT
    Secrets to inject into Cloud Run service as environment variables.
    These reference Secret Manager secrets (either created by this module or existing).
    Example:
    {
      "API_KEY" = {
        secret_name = "projects/PROJECT/secrets/api-key"
        version     = "latest"
      }
    }
  EOT
  type = map(object({
    secret_name = string
    version     = optional(string, "latest")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Scaling Configuration
# -----------------------------------------------------------------------------

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "concurrency" {
  description = "Maximum concurrent requests per instance"
  type        = number
  default     = 80
}

# -----------------------------------------------------------------------------
# Resource Limits
# -----------------------------------------------------------------------------

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

variable "env_vars" {
  description = "Environment variables for Cloud Run service"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Ingress and Authentication
# -----------------------------------------------------------------------------

variable "ingress" {
  description = "Ingress settings"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access"
  type        = bool
  default     = false
}

variable "invokers" {
  description = "List of members who can invoke this service"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Health Probes
# -----------------------------------------------------------------------------

variable "startup_probe" {
  description = "Startup probe configuration"
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 3)
    failure_threshold     = optional(number, 1)
    http_get = optional(object({
      path = string
      port = optional(number)
    }))
    tcp_socket = optional(object({
      port = optional(number)
    }))
  })
  default = null
}

variable "liveness_probe" {
  description = "Liveness probe configuration"
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 3)
    failure_threshold     = optional(number, 1)
    http_get = optional(object({
      path = string
      port = optional(number)
    }))
  })
  default = null
}
