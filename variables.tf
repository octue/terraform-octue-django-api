variable "project" {
  type    = string
  default = "bezier-app"
}


variable "region" {
  type    = string
  default = "europe-west1"
}


variable "resource_affix" {
  type    = string
  default = "bezier"
}


variable "environment" {
  type    = string
  default = "main"
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
  type    = string
  default = ""
}


variable "deletion_protection" {
  type    = bool
  default = false
}
