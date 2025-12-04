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
# AI Agents API Feature Configuration
# -----------------------------------------------------------------------------

variable "ai_agents_api_enabled" {
  description = "Whether to deploy the AI Agents API service"
  type        = bool
  default     = true
}

variable "ai_agents_api_image" {
  description = "Container image for the AI Agents API service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello:latest" # Placeholder
}

variable "ai_agents_api_min_instances" {
  description = "Minimum instances for AI Agents API"
  type        = number
  default     = 0
}

variable "ai_agents_api_max_instances" {
  description = "Maximum instances for AI Agents API"
  type        = number
  default     = 10
}

variable "ai_agents_api_cpu" {
  description = "CPU limit for AI Agents API"
  type        = string
  default     = "1"
}

variable "ai_agents_api_memory" {
  description = "Memory limit for AI Agents API"
  type        = string
  default     = "512Mi"
}

variable "ai_agents_api_concurrency" {
  description = "Max concurrent requests per instance for AI Agents API"
  type        = number
  default     = 80
}

variable "ai_agents_api_env_vars" {
  description = "Environment variables for AI Agents API"
  type        = map(string)
  default = {
    LOG_LEVEL = "debug"
  }
}

variable "ai_agents_api_allow_unauthenticated" {
  description = "Allow unauthenticated access to AI Agents API"
  type        = bool
  default     = false
}

variable "ai_agents_api_invokers" {
  description = "List of members who can invoke the AI Agents API"
  type        = list(string)
  default     = []
}
