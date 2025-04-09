# CARE REQUIRED!
#
# It takes 7 days to recreate task queues with the same name!
#
# While data loss is unlikely to occur (other than potentially dropping some tasks) it's nevertheless a pain.
#
# Should you accidentally do so, add a suffix to the name (like -default-0) and update environments to point to the new
# name, until 7 days has elapsed and you're able to revert.
locals {
  queue_suffix = var.tasks_queue_suffix != null && var.tasks_queue_suffix != "" ? "-${var.tasks_queue_suffix}" : ""
}


resource "google_cloud_tasks_queue" "default" {
  name      = "${var.resource_affix}--default${local.queue_suffix}--${var.environment}"
  location  = var.region
}


resource "google_cloud_tasks_queue_iam_member" "default_queue_task_create" {
  for_each = local.service_account_emails
  name = google_cloud_tasks_queue.default.name
  location = google_cloud_tasks_queue.default.location
  role = "roles/cloudtasks.enqueuer"
  member = each.value
}
