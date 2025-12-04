# -----------------------------------------------------------------------------
# Cloud Run V2 Service Module
# -----------------------------------------------------------------------------
# This module deploys a Cloud Run V2 service with configurable settings for:
# - Container image and scaling
# - Environment variables and secrets
# - Ingress and authentication
# - Service account and labels
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  # Ingress settings: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY,
  # INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER
  ingress = var.ingress

  labels = var.labels

  template {
    # Service account for the Cloud Run service
    service_account = var.service_account_email

    labels = var.labels

    # Scaling configuration
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # Container configuration
    containers {
      image = var.container_image

      # Resource limits
      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      # Port configuration
      ports {
        container_port = var.container_port
      }

      # Environment variables (non-secret)
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret environment variables from Secret Manager
      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = try(env.value.version, "latest")
            }
          }
        }
      }

      # Volume mounts for secrets (if needed as files)
      dynamic "volume_mounts" {
        for_each = var.secret_volumes
        content {
          name       = volume_mounts.key
          mount_path = volume_mounts.value.mount_path
        }
      }

      # Health check / startup probe (optional)
      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        content {
          initial_delay_seconds = try(startup_probe.value.initial_delay_seconds, 0)
          timeout_seconds       = try(startup_probe.value.timeout_seconds, 1)
          period_seconds        = try(startup_probe.value.period_seconds, 3)
          failure_threshold     = try(startup_probe.value.failure_threshold, 1)

          dynamic "http_get" {
            for_each = try(startup_probe.value.http_get, null) != null ? [startup_probe.value.http_get] : []
            content {
              path = http_get.value.path
              port = try(http_get.value.port, var.container_port)
            }
          }

          dynamic "tcp_socket" {
            for_each = try(startup_probe.value.tcp_socket, null) != null ? [startup_probe.value.tcp_socket] : []
            content {
              port = try(tcp_socket.value.port, var.container_port)
            }
          }
        }
      }

      # Liveness probe (optional)
      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          initial_delay_seconds = try(liveness_probe.value.initial_delay_seconds, 0)
          timeout_seconds       = try(liveness_probe.value.timeout_seconds, 1)
          period_seconds        = try(liveness_probe.value.period_seconds, 3)
          failure_threshold     = try(liveness_probe.value.failure_threshold, 1)

          dynamic "http_get" {
            for_each = try(liveness_probe.value.http_get, null) != null ? [liveness_probe.value.http_get] : []
            content {
              path = http_get.value.path
              port = try(http_get.value.port, var.container_port)
            }
          }
        }
      }
    }

    # Secret volumes (mount secrets as files)
    dynamic "volumes" {
      for_each = var.secret_volumes
      content {
        name = volumes.key
        secret {
          secret = volumes.value.secret_name
          items {
            version = try(volumes.value.version, "latest")
            path    = volumes.value.file_name
          }
        }
      }
    }

    # Execution environment
    execution_environment = var.execution_environment

    # Request timeout
    timeout = var.request_timeout

    # Max concurrent requests per instance
    max_instance_request_concurrency = var.concurrency
  }

  # Traffic configuration - all traffic to latest revision
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to client info (set by Cloud Console)
      client,
      client_version,
    ]
  }
}

# -----------------------------------------------------------------------------
# IAM Policy for Cloud Run Service
# -----------------------------------------------------------------------------
# Control who can invoke this Cloud Run service.
# Set allow_unauthenticated = true for public access (e.g., webhooks, public APIs)
# Set allow_unauthenticated = false for IAM-secured services
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service_iam_member" "invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = google_cloud_run_v2_service.service.project
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Additional invokers (for IAM-secured services)
resource "google_cloud_run_v2_service_iam_member" "additional_invokers" {
  for_each = toset(var.invokers)

  project  = google_cloud_run_v2_service.service.project
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = each.value
}
