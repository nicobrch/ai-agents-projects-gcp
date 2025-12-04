# -----------------------------------------------------------------------------
# Terraform Configuration
# -----------------------------------------------------------------------------
# Specifies required Terraform version and providers.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 7.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0.0, < 7.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Google Provider
# -----------------------------------------------------------------------------
# Uses Application Default Credentials (ADC) for authentication.
# No credentials are hardcoded - relies on:
# - gcloud auth application-default login (local development)
# - Service account key (CI/CD)
# - Workload Identity (GKE, Cloud Build)
# -----------------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = var.region

  # Add default labels to all resources that support them
  default_labels = local.common_labels
}

provider "google-beta" {
  project = var.project_id
  region  = var.region

  default_labels = local.common_labels
}
