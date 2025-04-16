resource "google_service_account" "server_service_account" {
  account_id   = "${var.resource_affix}--server--${var.environment}"
  description  = "Operate the ${var.environment} server with access to its environment-specific resources"
  display_name = "${var.resource_affix}--server--${var.environment}"
  project      = var.google_cloud_project_id
}


resource "google_service_account" "maintainers" {
  for_each     = var.maintainer_service_account_names
  account_id   = "maintainer-${each.key}"
  display_name = "maintainer-${each.key}"
  project      = var.google_cloud_project_id
  description  = "Allow ${each.key} to access most resources related to Octue Twined services."
}
