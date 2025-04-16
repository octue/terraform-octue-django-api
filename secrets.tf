resource "google_secret_manager_secret" "secrets" {
  for_each  = setunion(var.secret_names, ["google-application-credentials"])
  secret_id = "${var.resource_affix}--${each.value}--${var.environment}"
  replication {
    auto {}
  }
}


resource "google_secret_manager_secret_iam_member" "service_account_secret_access" {
  for_each   = google_secret_manager_secret.secrets
  secret_id  = each.value.secret_id
  role       = "roles/secretmanager.secretAccessor"
  member     = local.server_service_account_email
  depends_on = [google_secret_manager_secret.secrets]
}
