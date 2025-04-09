locals {
  django = {
    GCP_RESOURCE_AFFIX = var.resource_affix
    GCP_ENVIRONMENT    = var.environment
    GCP_PROJECT_ID     = var.project
  }
}


output "django_json" {
  description = "The Django settings for the environment"
  value       = jsonencode(local.django)
}


output "server_service_account" {
  value = google_service_account.server_service_account
}
