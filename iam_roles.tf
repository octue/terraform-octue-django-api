locals {
  server_service_account_email = "serviceAccount:${google_service_account.server_service_account.email}"
  maintainer_service_account_emails = toset(
    [for email in var.maintainer_service_account_emails : "serviceAccount:${email}"]
  )
}


resource "google_project_iam_member" "iam__service_account_user" {
  project = var.google_cloud_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = local.server_service_account_email
}


resource "google_project_iam_member" "run__developer" {
  project = var.google_cloud_project_id
  role    = "roles/run.developer"
  member  = local.server_service_account_email
}


resource "google_project_iam_member" "storage__object_admin" {
  project = var.google_cloud_project_id
  role    = "roles/storage.objectAdmin"
  member  = local.server_service_account_email
}


resource "google_project_iam_member" "error_reporting__writer" {
  project = var.google_cloud_project_id
  role    = "roles/errorreporting.writer"
  member  = local.server_service_account_email
}


resource "google_project_iam_member" "cloudsql__client" {
  project = var.google_cloud_project_id
  role    = "roles/cloudsql.client"
  member  = local.server_service_account_email
}


# Ensure maintainers can connect to, import and export from production/staging databases via cloudsql from
# terminals
#  - https://cloud.google.com/sql/docs/mysql/iam-roles
#  - https://cloud.google.com/sql/docs/mysql/iam-permissions
resource "google_project_iam_member" "cloudsql_maintainers" {
  for_each = local.maintainer_service_account_emails
  project  = var.google_cloud_project_id
  role     = "roles/cloudsql.editor"
  member   = each.value
}


# TODO REFACTOR REQUEST servers shouldn't be allowed to create and delete queues
# just to add tasks to them!
# Allow django-gcp.tasks to create and update task queues
# resource "google_project_iam_member" "cloudtasks_admin" {
#   project = var.project
#   role = "roles/cloudtasks.admin"
#   members = local.operational_members
# }


# Allow django-gcp.tasks to create periodic tasks in google cloud scheduler
resource "google_project_iam_member" "cloudscheduler__admin" {
  project = var.google_cloud_project_id
  role    = "roles/cloudscheduler.admin"
  member  = local.server_service_account_email
}


# Allow the server to pull secrets.
resource "google_project_iam_member" "secretmanager__secret_accessor" {
  project = var.google_cloud_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = local.server_service_account_email
}
