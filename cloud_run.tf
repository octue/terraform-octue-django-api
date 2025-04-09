resource "google_cloud_run_v2_service" "server" {
  name     = "${var.resource_affix}--server--${var.environment}"
  project  = var.project
  location = var.region

  ingress = "INGRESS_TRAFFIC_ALL"
  deletion_protection = var.deletion_protection

  template {
    service_account = google_service_account.server_service_account.email

    scaling {
      max_instance_count = 10
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.postgres_instance.connection_name]
      }
    }

    volumes {
      name = "credentials"
      secret {
        secret = "${var.resource_affix}--google-application-credentials--${var.environment}"
        items {
          version = "latest"
          path = "google-application-credentials"
        }
      }
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      volume_mounts {
        name = "cloudsql"
        mount_path = "/cloudsql"
      }

      volume_mounts {
        name = "credentials"
        mount_path = "/secrets"
      }

      dynamic "env" {
        for_each = var.secret_names
        content {
          name = upper(replace(env.value, "-", "_"))
          value_source {
            secret_key_ref {
              secret = "${var.resource_affix}--${env.value}--${var.environment}"
              version = "latest"
            }
          }
        }
      }

      env {
        name = "DJANGO_SETTINGS_MODULE"
        value = "server.settings.main"
      }

      env {
        name = "GCP_ENVIRONMENT"
        value = var.environment
      }

      env {
        name = "GCP_REGION"
        value = var.region
      }

      env {
        name = "GCP_RESOURCE_AFFIX"
        value = var.resource_affix
      }

      env {
        name = "GCP_TASKS_DEFAULT_QUEUE_NAME"
        value = google_cloud_tasks_queue.default.name
      }

      env {
        name = "GCP_TASKS_RESOURCE_AFFIX"
        value = "${var.resource_affix}--${var.environment}"
      }

      env {
        name = "GOOGLE_APPLICATION_CREDENTIALS"
        value = "/secrets/google-application-credentials"
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "2Gi"
        }
      }
    }

  }

  # Ignored for subsequent releases by GitHub Actions
  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }


  lifecycle {
    # TODO: The state was stale with revision creating changes
    # ignore_changes = [
    #   annotations["client.knative.dev/user-image"],
    #   template[0].annotations["client.knative.dev/user-image"],
    #   template[0].containers[0].image,
    #   traffic,
    #   client,
    #   client_version,
    #   template[0].revision,
    #   template[0].labels,
    # ]
    ignore_changes = all
  }

  depends_on = [google_secret_manager_secret.secrets]
}


# Set authentication to allow unauthorized invocations
resource "google_cloud_run_service_iam_member" "public_invoker" {
  service    = google_cloud_run_v2_service.server.name
  location   = var.region
  role       = "roles/run.invoker"
  member     = "allUsers"
}


resource "google_cloud_run_v2_job" "manager" {
  name     = "${var.resource_affix}--manager--${var.environment}"
  project  = var.project
  location = var.region
  deletion_protection = var.deletion_protection

  template {
    template {
      service_account = google_service_account.server_service_account.email

      timeout = "3600s"

      max_retries = 0

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.postgres_instance.connection_name]
        }
      }

      volumes {
        name = "credentials"
        secret {
          secret = "${var.resource_affix}--google-application-credentials--${var.environment}"
          items {
            version = "latest"
            path = "google-application-credentials"
          }
        }
      }

      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"

        command = ["python", "manage.py"]

        args = ["check"]

        volume_mounts {
          name = "cloudsql"
          mount_path = "/cloudsql"
        }

        volume_mounts {
          name = "credentials"
          mount_path = "/secrets"
        }

        dynamic "env" {
          for_each = var.secret_names
          content {
            name = upper(replace(env.value, "-", "_"))
            value_source {
              secret_key_ref {
                secret = "${var.resource_affix}--${env.value}--${var.environment}"
                version = "latest"
              }
            }
          }
        }

        env {
          name = "DJANGO_SETTINGS_MODULE"
          value = "server.settings.main"
        }

        env {
          name = "GCP_ENVIRONMENT"
          value = var.environment
        }

        env {
          name = "GCP_REGION"
          value = var.region
        }

        env {
          name = "GCP_RESOURCE_AFFIX"
          value = var.resource_affix
        }

        env {
          name = "GCP_TASKS_DEFAULT_QUEUE_NAME"
          value = google_cloud_tasks_queue.default.name
        }

        env {
          name = "GCP_TASKS_RESOURCE_AFFIX"
          value = "${var.resource_affix}--${var.environment}"
        }

        env {
          name = "GOOGLE_APPLICATION_CREDENTIALS"
          value = "/secrets/google-application-credentials"
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "2Gi"
          }
        }
      }

    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].args,
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [google_secret_manager_secret.secrets]
}
