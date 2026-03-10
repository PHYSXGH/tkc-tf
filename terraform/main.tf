terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "tf-state-bucket-00"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "app" {
  provider = google

  location      = var.region
  repository_id = "${var.app_name}-repo"
  format        = "DOCKER"
  description   = "Docker images for ${var.app_name}"

  depends_on = [google_project_service.apis]
}

resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.app_name}-cr-sa"
  display_name = "Cloud Run SA for ${var.app_name}"
}

# Allow the SA to pull images from Artifact Registry
resource "google_project_iam_member" "artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# The CR service that runs the app
resource "google_cloud_run_v2_service" "app" {
  name     = var.app_name
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = "europe-west1-docker.pkg.dev/the-keyholding-company/cloud-run-source-deploy/tkc-service/tkc-service-git:latest"
      resources {
        cpu_idle = true
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        startup_cpu_boost = true
      }
    }
  }
  labels = {
    env = "default"
  }
  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.app,
  ]
}

# a BQ service account
resource "google_service_account" "bq_owner_sa" {
  account_id   = "${var.app_name}-bq-sa"
  display_name = "BQ SA for ${var.app_name}'s datasets"
}

# The dataset for the tables
resource "google_bigquery_dataset" "tkc_dataset" {
  dataset_id                  = "tkc_dataset"
  friendly_name               = "test"
  description                 = "A dataset for the interstellar route planner"
  location                    = "europe-west1"

  labels = {
    env = "default"
  }

  access {
    role          = "roles/bigquery.dataOwner"
    user_by_email = google_service_account.bq_owner_sa.email
  }

  access {
    role          = "roles/bigquery.dataViewer"
    user_by_email = google_service_account.cloud_run_sa.email
  }
}

# The table that holds the info on the distances between stars
resource "google_bigquery_table" "tkc_table" {
  dataset_id = google_bigquery_dataset.tkc_dataset.dataset_id
  table_id   = "stars"

  labels = {
    env = "default"
  }

  schema = <<EOF
[
  {
    "name": "id",
    "mode": "NULLABLE",
    "type": "STRING",
    "description": "",
    "fields": []
  },
  {
    "name": "name",
    "mode": "NULLABLE",
    "type": "STRING",
    "description": "",
    "fields": []
  },
  {
    "name": "connections",
    "mode": "REPEATED",
    "type": "RECORD",
    "description": "",
    "fields": [
      {
        "name": "id",
        "mode": "NULLABLE",
        "type": "STRING",
        "description": "",
        "fields": []
      },
      {
        "name": "hu",
        "mode": "NULLABLE",
        "type": "INTEGER",
        "description": "",
        "fields": []
      }
    ]
  }
]
EOF
}