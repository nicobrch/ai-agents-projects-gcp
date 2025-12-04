# -----------------------------------------------------------------------------
# Cloud Run V2 Service Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "project_id" {
  description = "GCP project ID where the service will be deployed"
  type        = string
}

variable "region" {
  description = "GCP region for the Cloud Run service (e.g., us-central1)"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy (e.g., gcr.io/project/image:tag or us-docker.pkg.dev/project/repo/image:tag)"
  type        = string
}

# -----------------------------------------------------------------------------
# Service Account
# -----------------------------------------------------------------------------

variable "service_account_email" {
  description = "Service account email for the Cloud Run service. If not provided, uses the default compute service account."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Scaling Configuration
# -----------------------------------------------------------------------------

variable "min_instances" {
  description = "Minimum number of instances (0 allows scale to zero)"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 100
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
  description = "CPU limit (e.g., '1', '2', '1000m')"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit (e.g., '512Mi', '1Gi', '2Gi')"
  type        = string
  default     = "512Mi"
}

variable "cpu_idle" {
  description = "Whether CPU should be throttled when idle (cost optimization)"
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Whether to allocate extra CPU during startup"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Container Configuration
# -----------------------------------------------------------------------------

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "request_timeout" {
  description = "Request timeout in seconds (max 3600)"
  type        = string
  default     = "300s"
}

variable "execution_environment" {
  description = "Execution environment: EXECUTION_ENVIRONMENT_GEN1 or EXECUTION_ENVIRONMENT_GEN2"
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"
}

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

variable "env_vars" {
  description = "Map of environment variable names to values"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Secrets (from Secret Manager)
# -----------------------------------------------------------------------------

variable "secrets" {
  description = <<-EOT
    Map of environment variable names to Secret Manager secrets.
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

variable "secret_volumes" {
  description = <<-EOT
    Map of volume names to Secret Manager secrets mounted as files.
    Example:
    {
      "certs" = {
        secret_name = "projects/PROJECT/secrets/tls-cert"
        mount_path  = "/etc/certs"
        file_name   = "cert.pem"
        version     = "latest"
      }
    }
  EOT
  type = map(object({
    secret_name = string
    mount_path  = string
    file_name   = string
    version     = optional(string, "latest")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Ingress and Authentication
# -----------------------------------------------------------------------------

variable "ingress" {
  description = "Ingress settings: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition = contains([
      "INGRESS_TRAFFIC_ALL",
      "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    ], var.ingress)
    error_message = "Ingress must be one of: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access (public). Set to false for IAM-secured services."
  type        = bool
  default     = false
}

variable "invokers" {
  description = "List of members who can invoke this service (e.g., 'serviceAccount:sa@project.iam.gserviceaccount.com')"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Labels to apply to the Cloud Run service"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Health Probes (Optional)
# -----------------------------------------------------------------------------

variable "startup_probe" {
  description = <<-EOT
    Startup probe configuration. Example:
    {
      initial_delay_seconds = 0
      timeout_seconds       = 1
      period_seconds        = 3
      failure_threshold     = 1
      http_get = {
        path = "/health"
        port = 8080
      }
    }
  EOT
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
  description = <<-EOT
    Liveness probe configuration. Same structure as startup_probe.
  EOT
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
