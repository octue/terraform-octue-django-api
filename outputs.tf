locals {
  django = {
    GCP_RESOURCE_AFFIX = var.resource_affix
    GCP_ENVIRONMENT    = var.environment
    GCP_PROJECT_ID     = var.project
  }
}


output "django_json" {
  value       = jsonencode(local.django)
  description = "The Django settings for the environment."
}


output "server_service_account" {
  value       = google_service_account.server_service_account
  description = "The service account for running the Django server."
}
