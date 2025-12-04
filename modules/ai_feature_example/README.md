# AI Feature Example Module

A composite module demonstrating how to combine core modules (project_apis, iam, secret_manager, cloud_run_service) into a complete feature deployment.

## Purpose

This module serves as a **template** for creating new AI features/services. It shows the recommended pattern for:
- Creating a dedicated service account with appropriate IAM roles
- Managing feature-specific secrets
- Deploying a Cloud Run service with proper configuration
- Enabling any additional APIs needed

## Usage

### Basic Usage

```hcl
module "ai_agents_api" {
  source = "../../modules/ai_feature_example"

  # Feature identification
  feature_name = "ai-agents-api"
  service_name = "ai-agents-api-dev"

  # GCP configuration
  project_id = "dev-ai-agents-projects"
  region     = "us-central1"

  # Container
  container_image = "us-docker.pkg.dev/dev-ai-agents-projects/ai-agents/api:latest"

  # Service account
  create_service_account = true
  service_account_id     = "ai-agents-api-sa"

  # Scaling
  min_instances = 0
  max_instances = 10

  # Environment
  env_vars = {
    LOG_LEVEL = "debug"
    ENV       = "dev"
  }

  # Secrets (inject from Secret Manager)
  cloud_run_secrets = {
    "OPENAI_API_KEY" = {
      secret_name = "projects/dev-ai-agents-projects/secrets/openai-api-key"
    }
  }

  # Labels
  labels = {
    env        = "dev"
    team       = "ai-platform"
    managed_by = "terraform"
  }
}
```

### Creating a New Feature

1. **Copy this module:**
   ```bash
   cp -r modules/ai_feature_example modules/my_new_feature
   ```

2. **Customize the new module:**
   - Adjust IAM roles in `main.tf` if different permissions are needed
   - Add feature-specific logic or resources
   - Update variable defaults as appropriate

3. **Wire it in environments:**
   ```hcl
   # In envs/dev/main.tf
   module "my_new_feature" {
     source = "../../modules/my_new_feature"

     feature_name = "my-new-feature"
     service_name = "my-new-feature-${var.env_name}"
     project_id   = var.project_id
     region       = var.region

     container_image = var.my_new_feature_image
     # ... other variables
   }
   ```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| feature_name | Name of the feature | `string` | n/a | yes |
| service_name | Cloud Run service name | `string` | n/a | yes |
| project_id | GCP project ID | `string` | n/a | yes |
| region | GCP region | `string` | n/a | yes |
| container_image | Container image | `string` | n/a | yes |
| create_service_account | Create dedicated SA | `bool` | `true` | no |
| service_account_id | SA ID to create | `string` | `null` | no |
| additional_apis | Extra APIs to enable | `list(string)` | `[]` | no |
| secrets | Secrets to create | `map(object)` | `{}` | no |
| cloud_run_secrets | Secrets to inject | `map(object)` | `{}` | no |
| min_instances | Min instances | `number` | `0` | no |
| max_instances | Max instances | `number` | `10` | no |
| env_vars | Environment variables | `map(string)` | `{}` | no |
| labels | Resource labels | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_url | Cloud Run service URL |
| service_name | Cloud Run service name |
| service_account_email | Service account email |
| secret_ids | Map of created secret IDs |

## Module Composition

This module internally uses:
- `../project_apis` - Enable additional APIs
- `../iam` - Create service account and IAM bindings
- `../secret_manager` - Create feature-specific secrets
- `../cloud_run_service` - Deploy the Cloud Run service

## IAM Roles

The following roles are automatically assigned to the service account:
- `roles/logging.logWriter` - Write logs to Cloud Logging
- `roles/secretmanager.secretAccessor` - Access secrets
- `roles/errorreporting.writer` - Report errors

Add additional roles by modifying the `bindings` in `main.tf`.
