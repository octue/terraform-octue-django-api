locals {
  services = {
    iam                   = "iam.googleapis.com"
    iam_credentials       = "iamcredentials.googleapis.com"
    artifact_registry     = "artifactregistry.googleapis.com"
    cloud_run             = "run.googleapis.com"
    secret_manager        = "secretmanager.googleapis.com"
    cloud_tasks           = "cloudtasks.googleapis.com"
    cloud_sql             = "sqladmin.googleapis.com"
    cloud_error_reporting = "clouderrorreporting.googleapis.com"
  }
}


resource "google_project_service" "services" {
  for_each           = local.services
  project            = var.project
  service            = each.value
  disable_on_destroy = false

  timeouts {
    create = "30m"
    update = "40m"
  }
}
