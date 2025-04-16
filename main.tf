terraform {
  required_version = ">= 1.8.0, <2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>6.28.0"
    }
  }
}


data "google_project" "project" {}
