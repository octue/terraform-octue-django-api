resource "google_sql_database_instance" "postgres_instance" {
    name                          = "${var.resource_affix}--dbinstance--${var.environment}"
    project                       = var.project
    region                        = var.region
    database_version              = "POSTGRES_16"
    deletion_protection           = var.deletion_protection
    settings {
        edition                   = "ENTERPRISE"
        tier                      = "db-f1-micro"
        deletion_protection_enabled = var.deletion_protection
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
    name = "django"
    password = "initial-password-change-after-creation-please"
    type = "BUILT_IN"
    instance = google_sql_database_instance.postgres_instance.name
    deletion_policy = "ABANDON"
}
