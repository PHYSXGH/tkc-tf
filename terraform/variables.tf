variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "the-keyholding-company"
}

variable "region" {
  description = "GCP region to deploy into"
  type        = string
  default     = "europe-west2"
}

variable "app_name" {
  description = "Name of the application (used for Cloud Run service, SA, repo)"
  type        = string
  default     = "tkc-service"
}