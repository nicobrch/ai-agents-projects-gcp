# Secret Manager Module

Creates Secret Manager secrets and optionally their initial versions.

## Usage

```hcl
module "secrets" {
  source = "../../modules/secret_manager"

  project_id = "my-gcp-project"

  secrets = {
    "api-key" = {
      replication   = "auto"
      initial_value = "my-dev-api-key"  # Only for dev/test
      labels        = { service = "ai-api" }
    }
    "db-password" = {
      replication       = "user_managed"
      replica_locations = ["us-central1", "us-east1"]
      # No initial_value - will be populated manually
    }
  }

  create_versions = true  # Set to false in production

  labels = {
    env        = "dev"
    managed_by = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The GCP project ID | `string` | n/a | yes |
| secrets | Map of secrets configuration | `map(object)` | `{}` | no |
| create_versions | Create initial secret versions | `bool` | `true` | no |
| default_location | Default location for replication | `string` | `"us-central1"` | no |
| labels | Labels for all secrets | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_ids | Map of secret names to full resource IDs |
| secret_names | Map of secret names to resource names |
| secrets | Full secret resource objects |
| secret_version_ids | Map of secrets to their version IDs |

## Notes

- Use `create_versions = false` in production to manage secret values externally
- Secret values in Terraform state are sensitive - consider using external secret management
- The `initial_value` field is useful for dev/test but should be avoided in production
