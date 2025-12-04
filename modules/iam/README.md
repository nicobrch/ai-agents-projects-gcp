# IAM Module

Manages project-level IAM bindings and service accounts using an additive (safe) approach.

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  project_id = "my-gcp-project"

  # Create service accounts
  service_accounts = {
    "ai-api-sa" = {
      display_name = "AI API Service Account"
      description  = "Service account for AI API Cloud Run service"
    }
    "ai-worker-sa" = {
      display_name = "AI Worker Service Account"
    }
  }

  # Assign roles to members (additive, safe)
  bindings = {
    "roles/run.invoker" = [
      "serviceAccount:ai-api-sa@my-gcp-project.iam.gserviceaccount.com"
    ]
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:ai-api-sa@my-gcp-project.iam.gserviceaccount.com",
      "serviceAccount:ai-worker-sa@my-gcp-project.iam.gserviceaccount.com"
    ]
    "roles/logging.logWriter" = [
      "serviceAccount:ai-api-sa@my-gcp-project.iam.gserviceaccount.com"
    ]
  }

  # Optional: allow users to impersonate service accounts
  service_account_impersonation = {
    "dev-impersonate" = {
      service_account = "ai-api-sa"
      member          = "user:developer@example.com"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The GCP project ID | `string` | n/a | yes |
| bindings | Map of role to list of members | `map(list(string))` | `{}` | no |
| service_accounts | Service accounts to create | `map(object)` | `{}` | no |
| service_account_impersonation | Impersonation grants | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_accounts | Map of created service accounts |
| service_account_emails | Map of SA names to emails |
| bindings | Map of IAM bindings created |

## Notes

- This module uses `google_project_iam_member` which is additive and safe
- It will NOT remove bindings not managed by this module
- Service accounts created here can be referenced in bindings using their email
