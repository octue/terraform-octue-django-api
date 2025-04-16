> [!IMPORTANT]
> This Terraform module must be deployed alongside the [terraform-octue-django-api-buckets](https://github.com/octue/terraform-octue-django-api-buckets)
> module.

# terraform-octue-django-api
A Terraform module for deploying a Django API server on Google Cloud Run.


# Infrastructure
Deploying this module creates a set of API infrastructure for a cloud environment. This infrastructure is [isolated 
from other environments' infrastructure](#environments). These resources are automatically deployed:
- A Cloud Run service and job
- A Google Cloud SQL PostgreSQL database
- A load balancer and external IP address 
- A number of empty secrets in Google Secret Manager
- A Google Cloud Tasks queue
- An IAM service account and roles for the Cloud Run service and job


# Installation and usage
Add the below blocks to your Terraform configuration and run:
```shell
terraform init
terraform plan
```

If you're happy with the plan, run:
```shell
terraform apply
```
and approve the run. Make sure to populate any secrets in the Secret Manager.


## Environments
The suggested way of managing environments is via [Terraform workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces).
You can get started right away with the `main` environment by removing the `environment` input to the module. 

To create and used other environments, see the example configuration below. It contains a `locals` block that 
automatically generates the environment name from the name of the current Terraform workspace by taking the text after 
the final hyphen. This supports uniquely named environments in Terraform Cloud (which must be unique within the 
organisation) while keeping the environment prefix short but unique within your GCP project. For this to work well, 
ensure your Terraform workspace names are slugified.

For example, if your resource affix was `my-project` and your Terraform workspace was called `my-project-testing`, the 
environment would be called `testing` and your resources would be named like this:
- Cloud Run service: `"my-project--server--testing"`
- Database: `"my-project--dbinstance--testing"`


## Example configuration

```terraform
# main.tf

terraform {
  required_version = ">= 1.8.0, <2"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.28.0"
    }
  }
}


provider "google" {
  project     = var.google_cloud_project_id
  region      = var.google_cloud_region
}


# Get the environment name from the workspace.
locals {
  workspace_split = split("-", terraform.workspace)
  environment = element(local.workspace_split, length(local.workspace_split) - 1)
}


module "octue_django_api" {
  source = "git::github.com/octue/terraform-octue-django-api.git?ref=0.1.0"
  project = var.google_cloud_project_id
  region = var.google_cloud_region
  resource_affix = var.resource_affix
  environment = local.environment
}


module "octue_django_api_buckets" {
  source = "git::github.com/octue/terraform-octue-django-api-buckets.git?ref=0.1.0"
  server_service_account_email = module.octue_django_api.server_service_account.email
  project = var.google_cloud_project_id
  resource_affix = var.resource_affix
  environment = local.environment
}
```

```terraform
# variables.tf

variable "google_cloud_project_id" {
  type    = string
  default = "<your-google-project-id>"
}


variable "google_cloud_region" {
  type    = string
  default = "<your-google-project-region>"
}


variable "resource_affix" {
  type    = string
  default = "<name-of-your-api>"
}
```

## Dependencies
- Terraform: `>= 1.8.0, <2`
- Providers:
  - `hashicorp/google`: `~>6.28`
- Google cloud APIs:
  - The Cloud Resource Manager API must be [enabled manually](https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com) 
    before using the module
  - All other required google cloud APIs are enabled automatically by the module 


## Authentication
The module needs to authenticate with google cloud before it can be used:

1. Create a service account for Terraform and assign it the `editor` and `owner` basic IAM permissions
2. Download a JSON key file for the service account
3. If using Terraform Cloud, follow [these instructions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#using-terraform-cloud).
   before deleting the key file from your computer 
4. If not using Terraform Cloud, follow [these instructions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication-configuration)
   or use another [authentication method](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication).


## Destruction
> [!WARNING]
> If the `deletion_protection` input is set to `true`, it must first be set to `false` and `terraform apply` run before 
> running `terraform destroy` or any other operation that would result in the destruction or replacement of the Cloud 
> Run service or database. Not doing this can lead to a state needing targeted Terraform commands and/or manual 
> configuration changes to recover from.

Disable `deletion_protection` and run:
```shell
terraform destroy
```


# Input reference

| Name                               | Type          | Required | Default                                                                                 |
|------------------------------------|---------------|----------|-----------------------------------------------------------------------------------------| 
| `google_cloud_project_id`          | `string`      | Yes      | N/A                                                                                     |  
| `google_cloud_region`              | `string`      | Yes      | N/A                                                                                     | 
| `resource_affix`                   | `string`      | Yes      | N/A                                                                                     |                 
| `environment`                      | `string`      | No       | `"main"`                                                                                |
| `maintainer_service_account_names` | `set(string)` | No       | `["default"]`                                                                           |
| `secret_names`                     | `set(string)` | No       | `set(["django-secret-key", "database-proxy-url", "database-url", "stripe-secret-key"])` |     
| `tasks_queue_name_suffix`          | `string`      | No       | `""`                                                                                    |     
| `deletion_protection`              | `bool`        | No       | `true`                                                                                  | 

See [`variables.tf`](/variables.tf) for descriptions.


# Output reference

| Name                     | Type                                            |
|--------------------------|-------------------------------------------------|
| `django_json`            | `string`                                        | 
| `server_service_account` | `google_service_account.server_service_account` | 

See [`outputs.tf`](/outputs.tf) for descriptions.
