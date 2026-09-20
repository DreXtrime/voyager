resource "google_project_service" "artifact_registry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

# Container image repository
resource "google_artifact_registry_repository" "containers" {
  project       = var.project_id
  location      = var.region
  repository_id = "containers"
  description   = "Docker container images for frontend and backend"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-last-10"
    action = "KEEP"

    most_recent_versions {
      keep_count = 10
    }
  }

  depends_on = [google_project_service.artifact_registry]
}

# Helm chart OCI repository
resource "google_artifact_registry_repository" "helm_charts" {
  project       = var.project_id
  location      = var.region
  repository_id = "helm-charts"
  description   = "Helm charts stored as OCI artifacts"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-last-10"
    action = "KEEP"

    most_recent_versions {
      keep_count = 10
    }
  }

  depends_on = [google_project_service.artifact_registry]
}

# Allow test project nodes to pull images
resource "google_artifact_registry_repository_iam_member" "test_containers_reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.containers.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_compute_default_service_account.test.email}"
}

resource "google_artifact_registry_repository_iam_member" "test_helm_reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.helm_charts.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_compute_default_service_account.test.email}"
}

# Allow prod project nodes to pull images
resource "google_artifact_registry_repository_iam_member" "prod_containers_reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.containers.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_compute_default_service_account.prod.email}"
}

resource "google_artifact_registry_repository_iam_member" "prod_helm_reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.helm_charts.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_compute_default_service_account.prod.email}"
}

# Default compute service accounts for test and prod projects
data "google_compute_default_service_account" "test" {
  project = var.test_project_id
}

data "google_compute_default_service_account" "prod" {
  project = var.prod_project_id
}

# Allow GitLab VM to push images and helm charts
resource "google_artifact_registry_repository_iam_member" "gitlab_containers_writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.containers.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_compute_default_service_account.shared.email}"
}

resource "google_artifact_registry_repository_iam_member" "gitlab_helm_writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.helm_charts.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_compute_default_service_account.shared.email}"
}

# Default compute service account for shared project (GitLab VM)
data "google_compute_default_service_account" "shared" {
  project = var.project_id
}
