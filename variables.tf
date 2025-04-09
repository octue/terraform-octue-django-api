variable "project" {
  type        = string
  default     = "bezier-app"
  description = "The ID of the GCP project to deploy in."
}


variable "region" {
  type        = string
  default     = "europe-west1"
  description = "The GCP region to deploy in"
}


variable "resource_affix" {
  type        = string
  default     = "bezier"
  description = "The affix to add to each resource controlled by this module."
}


variable "environment" {
  type        = string
  default     = "main"
  description = "The name of the environment to deploy the resources in (must be one word with no hyphens or underscores in). This can be derived from a Terraform workspace name and used to facilitate e.g. testing and staging environments alongside the production environment ('main')."
}


variable "secret_names" {
  description = "A list of secrets to be created and made accessible to the cloud run instance."
  type        = set(string)
  default = [
    "django-secret-key",
    "database-proxy-url",
    "database-url",
    "stripe-secret-key",
  ]
}


variable "tasks_queue_name_suffix" {
  type        = string
  default     = ""
  description = "An optional suffix to be added to the resource name of the task queue. Only use when attempting to recreate a queue after it has been deleted as a queue with the same name cannot be created within 7 days."
}


variable "deletion_protection" {
  type        = bool
  default     = false
  description = "If `true`, disallow deletion of the database and Cloud Run services. `terraform apply` must be run after setting this to `false` before `terraform destroy` will work."
}
