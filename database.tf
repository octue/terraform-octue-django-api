resource "google_sql_database_instance" "postgres_instance" {
  name                = "${var.resource_affix}--dbinstance--${var.environment}"
  project             = var.google_cloud_project_id
  region              = var.google_cloud_region
  database_version    = "POSTGRES_16"
  deletion_protection = var.deletion_protection
  settings {
    edition                     = "ENTERPRISE"
    tier                        = "db-f1-micro"
    deletion_protection_enabled = var.deletion_protection

    database_flags {
      name  = "max_connections"
      value = "400"
    }

    insights_config {
      query_insights_enabled = true
    }

    availability_type = var.database_availability_type

    backup_configuration {
      enabled = true
      point_in_time_recovery_enabled = true
    }
  }
  # If we need to execute SQL...
  #   provisioner "local-exec" {
  #     command = "PGPASSWORD=<password> psql -f schema.sql -p <port> -U <username> <databasename>"
  #   }

  timeouts {}
}

resource "google_sql_database" "postgres_database" {
  name     = "default"
  instance = google_sql_database_instance.postgres_instance.name
}

resource "google_sql_user" "postgres_database_users" {
  name            = "django"
  password        = "initial-password-change-after-creation-please"
  type            = "BUILT_IN"
  instance        = google_sql_database_instance.postgres_instance.name
  deletion_policy = "ABANDON"
}
