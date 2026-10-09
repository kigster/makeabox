output "web_url" {
  description = "Public URL of the web Cloud Run service"
  value       = google_cloud_run_v2_service.web.uri
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name (project:region:instance)"
  value       = google_sql_database_instance.postgres.connection_name
}

output "db_password_secret" {
  description = "Secret Manager secret id holding the database password"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "domain_dns_records" {
  description = "DNS records to create at the registrar for the custom domain (empty until the mapping exists)"
  value = var.domain == "" ? [] : [
    for r in google_cloud_run_domain_mapping.web_domain[0].status[0].resource_records : {
      name  = r.name
      type  = r.type
      value = r.rrdata
    }
  ]
}
