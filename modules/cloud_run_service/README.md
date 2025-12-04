# Cloud Run V2 Service Module

Deploys a Cloud Run V2 service with configurable scaling, secrets, and authentication.

## Usage

### Basic Service

```hcl
module "api_service" {
  source = "../../modules/cloud_run_service"

  service_name    = "ai-api"
  project_id      = "my-gcp-project"
  region          = "us-central1"
  container_image = "us-docker.pkg.dev/my-project/repo/ai-api:latest"

  min_instances = 0
  max_instances = 10
  concurrency   = 80

  env_vars = {
    LOG_LEVEL = "info"
    ENV       = "dev"
  }

  labels = {
    env        = "dev"
    service    = "ai-api"
    managed_by = "terraform"
  }
}
```

### Service with Secrets and Custom Service Account

```hcl
module "api_service" {
  source = "../../modules/cloud_run_service"

  service_name          = "ai-api"
  project_id            = "my-gcp-project"
  region                = "us-central1"
  container_image       = "us-docker.pkg.dev/my-project/repo/ai-api:v1.2.3"
  service_account_email = "ai-api-sa@my-gcp-project.iam.gserviceaccount.com"

  min_instances = 1
  max_instances = 100
  concurrency   = 100

  cpu_limit    = "2"
  memory_limit = "2Gi"

  env_vars = {
    LOG_LEVEL = "info"
  }

  secrets = {
    "API_KEY" = {
      secret_name = "projects/my-gcp-project/secrets/api-key"
      version     = "latest"
    }
    "DB_PASSWORD" = {
      secret_name = "projects/my-gcp-project/secrets/db-password"
    }
  }

  # IAM-secured service (requires authentication)
  allow_unauthenticated = false
  invokers = [
    "serviceAccount:other-service@my-gcp-project.iam.gserviceaccount.com"
  ]

  labels = {
    env        = "prod"
    service    = "ai-api"
    managed_by = "terraform"
  }
}
```

### Public Service (Unauthenticated)

```hcl
module "webhook_service" {
  source = "../../modules/cloud_run_service"

  service_name          = "webhook-handler"
  project_id            = "my-gcp-project"
  region                = "us-central1"
  container_image       = "us-docker.pkg.dev/my-project/repo/webhook:latest"
  allow_unauthenticated = true  # Public access

  labels = {
    env     = "prod"
    service = "webhook"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| service_name | Name of the Cloud Run service | `string` | n/a | yes |
| project_id | GCP project ID | `string` | n/a | yes |
| region | GCP region | `string` | n/a | yes |
| container_image | Container image to deploy | `string` | n/a | yes |
| service_account_email | Service account email | `string` | `null` | no |
| min_instances | Minimum instances | `number` | `0` | no |
| max_instances | Maximum instances | `number` | `100` | no |
| concurrency | Max concurrent requests | `number` | `80` | no |
| cpu_limit | CPU limit | `string` | `"1"` | no |
| memory_limit | Memory limit | `string` | `"512Mi"` | no |
| env_vars | Environment variables | `map(string)` | `{}` | no |
| secrets | Secret Manager secrets | `map(object)` | `{}` | no |
| ingress | Ingress setting | `string` | `"INGRESS_TRAFFIC_ALL"` | no |
| allow_unauthenticated | Allow public access | `bool` | `false` | no |
| invokers | List of authorized invokers | `list(string)` | `[]` | no |
| labels | Resource labels | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_id | Unique identifier |
| service_name | Service name |
| service_url | Service URL |
| service_location | Service region |
| latest_revision | Latest revision name |
| service_account | Service account used |

## Notes

- Uses Cloud Run V2 API (`google_cloud_run_v2_service`)
- Supports both public and IAM-secured services
- Secrets are referenced from Secret Manager (not stored in Terraform state)
- Default execution environment is Gen2 (better cold start performance)
