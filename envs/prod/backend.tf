# -----------------------------------------------------------------------------
# Terraform Backend Configuration - Production
# -----------------------------------------------------------------------------
# Uses Google Cloud Storage (GCS) for remote state storage.
#
# IMPORTANT: The GCS bucket must be created manually BEFORE running terraform init.
#
# Create the bucket with:
#   gcloud storage buckets create gs://prod-ai-agents-projects-tfstate \
#     --project=prod-ai-agents-projects \
#     --location=us-central1 \
#     --uniform-bucket-level-access
#
#   gcloud storage buckets update gs://prod-ai-agents-projects-tfstate --versioning
#
# The bucket should have:
# - Versioning enabled (for state recovery)
# - Uniform bucket-level access (recommended)
# - Appropriate IAM permissions for the Terraform executor
# - Consider enabling Object Lock for production state protection
# -----------------------------------------------------------------------------

terraform {
  backend "gcs" {
    # GCS bucket for Terraform state
    # This bucket must exist before running terraform init
    bucket = "prod-ai-agents-projects-tfstate"

    # Prefix within the bucket (allows multiple states in one bucket)
    prefix = "terraform/state"
  }
}
