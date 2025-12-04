# -----------------------------------------------------------------------------
# Variables - Development Environment
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID for the development environment"
  type        = string
}

variable "project_number" {
  description = "GCP project number (numeric) for Workload Identity Federation"
  type        = string
}

variable "env_name" {
  description = "Environment name (e.g., 'dev', 'prod')"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Default GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "Default GCP location (for multi-regional resources)"
  type        = string
  default     = "us"
}

# -----------------------------------------------------------------------------
# Workload Identity Federation
# -----------------------------------------------------------------------------

variable "workload_identity_pool_id" {
  description = "Workload Identity Pool ID for GitHub Actions authentication"
  type        = string
  default     = "github-pool"
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "owner" {
  description = "Owner of the resources (for labeling)"
  type        = string
  default     = "ai-platform-team"
}

variable "additional_labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# APIs Configuration
# -----------------------------------------------------------------------------

variable "enabled_apis" {
  description = "List of GCP APIs to enable"
  type        = list(string)
  default = [
    "run.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "enable_ai_apis" {
  description = "Whether to enable AI Platform APIs (Vertex AI, etc.)"
  type        = bool
  default     = false
}

variable "ai_apis" {
  description = "List of AI-related APIs to enable when enable_ai_apis is true"
  type        = list(string)
  default = [
    "aiplatform.googleapis.com",
    "ml.googleapis.com",
  ]
}

# -----------------------------------------------------------------------------
# Secrets Configuration
# -----------------------------------------------------------------------------

variable "secrets" {
  description = <<-EOT
    Map of secrets to create in Secret Manager.
    Example:
    {
      "openai-api-key" = {
        replication   = "auto"
        initial_value = "sk-dev-xxx"  # Only for dev
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

variable "create_secret_versions" {
  description = "Whether to create initial secret versions (set to false in prod)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------

variable "service_accounts" {
  description = <<-EOT
    Map of service accounts to create.
    Example:
    {
      "ai-agents-api-sa" = {
        display_name = "AI Agents API Service Account"
        description  = "SA for AI Agents API service"
      }
    }
  EOT
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
  }))
  default = {}
}

variable "iam_bindings" {
  description = <<-EOT
    Map of IAM role to list of members.
    Example:
    {
      "roles/secretmanager.secretAccessor" = [
        "serviceAccount:ai-agents-api-sa@project.iam.gserviceaccount.com"
      ]
    }
  EOT
  type    = map(list(string))
  default = {}
}

# -----------------------------------------------------------------------------
# Luca API Feature Configuration
# -----------------------------------------------------------------------------

variable "luca_enabled" {
  description = "Whether to deploy the Luca API service"
  type        = bool
  default     = true
}

variable "luca_image" {
  description = "Container image for the Luca API service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello:latest" # Placeholder
}

variable "luca_min_instances" {
  description = "Minimum instances for Luca API"
  type        = number
  default     = 0
}

variable "luca_max_instances" {
  description = "Maximum instances for Luca API"
  type        = number
  default     = 10
}

variable "luca_cpu" {
  description = "CPU limit for Luca API"
  type        = string
  default     = "1"
}

variable "luca_memory" {
  description = "Memory limit for Luca API"
  type        = string
  default     = "512Mi"
}

variable "luca_concurrency" {
  description = "Max concurrent requests per instance for Luca API"
  type        = number
  default     = 80
}

variable "luca_env_vars" {
  description = "Environment variables for Luca API"
  type        = map(string)
  default = {
    LOG_LEVEL = "debug"
  }
}

variable "luca_secrets" {
  description = <<-EOT
    Secrets to inject into Luca Cloud Run service.
    Example:
    {
      "GOOGLE_API_KEY" = {
        secret_name = "projects/PROJECT/secrets/google-api-key"
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

variable "luca_allow_unauthenticated" {
  description = "Allow unauthenticated access to Luca API"
  type        = bool
  default     = false
}

variable "luca_invokers" {
  description = "List of members who can invoke the Luca API"
  type        = list(string)
  default     = []
}

variable "luca_github_repo" {
  description = "GitHub repository for Luca (owner/repo format) for Workload Identity Federation"
  type        = string
  default     = ""
}
