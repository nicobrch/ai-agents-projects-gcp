# Scripts

Helper scripts for managing Terraform operations.

## tf.sh

Main helper script for running Terraform commands across environments.

### Usage

```bash
./scripts/tf.sh <environment> <command> [options]
```

### Examples

```bash
# Initialize dev environment
./scripts/tf.sh dev init

# Plan changes in dev
./scripts/tf.sh dev plan

# Apply changes to dev
./scripts/tf.sh dev apply

# Apply with auto-approve (use with caution!)
./scripts/tf.sh dev apply -auto-approve

# Plan changes in production
./scripts/tf.sh prod plan

# Format all Terraform files
./scripts/tf.sh all fmt

# Validate all configurations
./scripts/tf.sh all validate
```

### Environments

- `dev` - Development environment
- `prod` - Production environment
- `all` - All environments (only for `fmt` and `validate`)

### Commands

- `init` - Initialize Terraform
- `plan` - Plan changes
- `apply` - Apply changes
- `destroy` - Destroy infrastructure
- `fmt` - Format Terraform files
- `validate` - Validate configuration
- `output` - Show outputs

## setup-state-buckets.sh

Creates the GCS buckets needed for Terraform remote state storage.

### Usage

```bash
./scripts/setup-state-buckets.sh
```

This script will:
1. Create state buckets in both dev and prod projects
2. Enable versioning on the buckets
3. Configure uniform bucket-level access

Run this **once** before initializing Terraform for the first time.

## Prerequisites

- Bash shell
- `gcloud` CLI installed and authenticated
- Terraform installed (version specified in `.terraform-version`)
- Appropriate GCP permissions

## Making Scripts Executable

On Unix-like systems:
```bash
chmod +x scripts/*.sh
```

On Windows (Git Bash):
```bash
# Scripts should work in Git Bash without modification
```
