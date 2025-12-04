# Project APIs Module

Enables GCP APIs/services for a project.

## Usage

```hcl
module "project_apis" {
  source = "../../modules/project_apis"

  project_id = "my-gcp-project"
  apis = [
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The GCP project ID | `string` | n/a | yes |
| apis | List of APIs to enable | `list(string)` | `[]` | no |
| disable_on_destroy | Disable API on resource destroy | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| enabled_apis | List of enabled API names |
| enabled_apis_map | Map of enabled APIs with details |
