# GCP AI Agents Infrastructure

Terraform repository for managing GCP AI-related infrastructure across multiple environments (dev, prod).

## Repository Structure

```
.
├── modules/                      # Reusable Terraform modules
│   ├── project_apis/             # Enable GCP APIs
│   ├── secret_manager/           # Secret Manager secrets
│   ├── iam/                      # IAM bindings and service accounts
│   ├── cloud_run_service/        # Cloud Run V2 services
│   └── ai_feature_example/       # Example feature module (composing core modules)
├── envs/                         # Environment configurations
│   ├── dev/                      # Development environment
│   └── prod/                     # Production environment
├── scripts/                      # Helper scripts for Terraform operations
├── .gitignore
├── .terraform-version            # Terraform version (for tfenv)
└── README.md
```

## Architecture

### Module Design

- **Core Modules** (`project_apis`, `secret_manager`, `iam`, `cloud_run_service`): Small, focused modules for specific GCP resources
- **Feature Modules** (`ai_feature_example`): Composite modules that combine core modules to deploy a complete feature/service

### Extending the Infrastructure

To add a new AI feature/service:

1. **Create a new feature module** (optional, but recommended for complex features):
   ```bash
   cp -r modules/ai_feature_example modules/my_new_feature
   # Modify the new module as needed
   ```

2. **Wire it in each environment**:
   - Add module block in `envs/dev/main.tf` and `envs/prod/main.tf`
   - Add corresponding variables in `variables.tf`
   - Add outputs in `outputs.tf`
   - Update `terraform.tfvars` with values

3. **For simple additions**:
   - Add secrets: Update the `secrets` map in `terraform.tfvars`
   - Add IAM bindings: Update the `iam_bindings` map in `terraform.tfvars`
   - Enable APIs: Update the `enabled_apis` list in `terraform.tfvars`

## Prerequisites

### 1. GCP Authentication

This project uses Application Default Credentials (ADC). Set up authentication:

```bash
# Authenticate with your user account
gcloud auth application-default login

# Or use a service account (recommended for CI/CD)
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# Or use service account impersonation (recommended)
gcloud auth application-default login --impersonate-service-account=terraform@YOUR_PROJECT.iam.gserviceaccount.com
```

### 2. Create Terraform State Buckets

Before running Terraform, manually create GCS buckets for state storage:

```bash
# For development
gcloud storage buckets create gs://dev-ai-agents-projects-tfstate \
  --project=dev-ai-agents-projects \
  --location=us-central1 \
  --uniform-bucket-level-access

# Enable versioning for state recovery
gcloud storage buckets update gs://dev-ai-agents-projects-tfstate --versioning

# For production
gcloud storage buckets create gs://prod-ai-agents-projects-tfstate \
  --project=prod-ai-agents-projects \
  --location=us-central1 \
  --uniform-bucket-level-access

gcloud storage buckets update gs://prod-ai-agents-projects-tfstate --versioning
```

### 3. Required Permissions

The identity running Terraform needs these roles on each GCP project:
- `roles/editor` or specific roles:
  - `roles/run.admin`
  - `roles/iam.serviceAccountAdmin`
  - `roles/iam.securityAdmin`
  - `roles/secretmanager.admin`
  - `roles/serviceusage.serviceUsageAdmin`
  - `roles/storage.admin` (for state bucket)

## Usage

### Initialize Terraform

```bash
cd envs/dev  # or envs/prod

# Create your tfvars file from example
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init
```

### Plan and Apply

```bash
# Review planned changes
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"
```

### Using Helper Scripts

```bash
# From repository root
./scripts/tf.sh dev plan    # Plan for dev environment
./scripts/tf.sh dev apply   # Apply to dev environment
./scripts/tf.sh prod plan   # Plan for prod environment
./scripts/tf.sh all fmt     # Format all Terraform files
./scripts/tf.sh all validate # Validate all configurations
```

## Environments

| Environment | GCP Project             | State Bucket                        |
|-------------|-------------------------|-------------------------------------|
| dev         | dev-ai-agents-projects  | dev-ai-agents-projects-tfstate      |
| prod        | prod-ai-agents-projects | prod-ai-agents-projects-tfstate     |

## Best Practices

1. **Always plan before apply**: Review changes carefully, especially in production
2. **Use consistent naming**: `{service}-{env}` pattern (e.g., `ai-agents-api-dev`)
3. **Label everything**: All resources include `env`, `service`, `managed_by` labels
4. **Keep secrets out of code**: Use `terraform.tfvars` (gitignored) for sensitive values
5. **Test in dev first**: Always deploy to dev before prod

## Troubleshooting

### State Lock Issues

If Terraform state is locked:
```bash
terraform force-unlock LOCK_ID
```

### API Enable Errors

If APIs fail to enable, wait a few minutes and retry. Some APIs have propagation delays.

### Permission Errors

Ensure your authenticated identity has the required roles listed in Prerequisites.
