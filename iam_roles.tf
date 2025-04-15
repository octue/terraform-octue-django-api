locals {
  service_account_emails = toset(
    [
      "serviceAccount:${google_service_account.server_service_account.email}",
    ]
  )
}


resource "google_project_iam_member" "iam__service_account_user" {
  for_each = local.service_account_emails
  project  = var.google_cloud_project_id
  role     = "roles/iam.serviceAccountUser"
  member   = each.value
}


# Allows the GHA to call "namespaces get" for Cloud Run to determine the resulting run URLs of the services.
# This should also allow a service to get its own name by using:
#   https://stackoverflow.com/questions/65628822/google-cloud-run-can-a-service-know-its-own-url/65634104#65634104
resource "google_project_iam_member" "run__developer" {
  for_each = local.service_account_emails
  project  = var.google_cloud_project_id
  role     = "roles/run.developer"
  member   = each.value
}


resource "google_project_iam_member" "storage__object_admin" {
  for_each = local.service_account_emails
  project  = var.google_cloud_project_id
  role     = "roles/storage.objectAdmin"
  member   = each.value
}


resource "google_project_iam_member" "error_reporting__writer" {
  project = var.google_cloud_project_id
  role    = "roles/errorreporting.writer"
  member  = "serviceAccount:${google_service_account.server_service_account.email}"
}


resource "google_project_iam_member" "cloudsql__client" {
  for_each = local.service_account_emails
  project  = var.google_cloud_project_id
  role     = "roles/cloudsql.client"
  member   = each.value
}


# Ensure superuser developers can connect to, import and export from
# production/staging databases via cloudsql from terminals
#   https://cloud.google.com/sql/docs/mysql/iam-roles
#   https://cloud.google.com/sql/docs/mysql/iam-permissions
# resource "google_project_iam_member" "cloudsql_superusers" {
#   project = var.project
#   role    = "roles/cloudsql.editor"
#   members = [
#     local.server_service_accounts["thclark"].member_signature,
#     local.server_service_accounts["cortadocodes"].member_signature,
#     local.server_service_accounts["nvnnil"].member_signature
#   ]
# }


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
  for_each = local.service_account_emails
  project  = var.google_cloud_project_id
  role     = "roles/cloudscheduler.admin"
  member   = each.value
}


# Allow the server to pull
resource "google_project_iam_member" "secretmanager__secret_accessor" {
  for_each = local.service_account_emails
  project  = var.google_cloud_project_id
  role     = "roles/secretmanager.secretAccessor"
  member   = each.value
}
