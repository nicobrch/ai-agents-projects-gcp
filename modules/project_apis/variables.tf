# -----------------------------------------------------------------------------
# Project APIs Module - Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID where APIs will be enabled"
  type        = string
}

variable "apis" {
  description = "List of GCP APIs to enable (e.g., ['run.googleapis.com', 'secretmanager.googleapis.com'])"
  type        = list(string)
  default     = []
}

variable "disable_on_destroy" {
  description = "Whether to disable the API when the resource is destroyed. Set to false (default) for safety in production."
  type        = bool
  default     = false
}

variable "disable_dependent_services" {
  description = "Whether to disable dependent services when disabling a service. Only relevant if disable_on_destroy = true."
  type        = bool
  default     = false
}

variable "timeout_create" {
  description = "Timeout for API enablement"
  type        = string
  default     = "20m"
}

variable "timeout_update" {
  description = "Timeout for API updates"
  type        = string
  default     = "20m"
}
