output "cloud_run_url" {
  description = "Public URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.app.uri
}

output "cloud_run_service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloud_run_sa.email
}

output "bigquery_service_account_email" {
  description = "Email of the BQ service account"
  value       = google_service_account.bq_owner_sa.email
}