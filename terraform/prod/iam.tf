resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"

  disable_on_destroy = false
}

# -------------------------
# External DNS
# -------------------------
resource "google_service_account" "external_dns" {
  project      = var.project_id
  account_id   = "external-dns-${var.environment}"
  display_name = "External DNS - ${var.environment}"
}

resource "google_project_iam_member" "external_dns_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.external_dns.email}"
}

# Workload Identity binding for External DNS
resource "google_service_account_iam_member" "external_dns_workload_identity" {
  service_account_id = google_service_account.external_dns.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]"
  depends_on         = [google_container_cluster.main]
}

# -------------------------
# Loki
# -------------------------
resource "google_service_account" "loki" {
  project      = var.project_id
  account_id   = "loki-${var.environment}"
  display_name = "Loki - ${var.environment}"
}

resource "google_storage_bucket_iam_member" "loki_logs_admin" {
  bucket = google_storage_bucket.logs.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.loki.email}"
}

# Workload Identity binding for Loki
resource "google_service_account_iam_member" "loki_workload_identity" {
  service_account_id = google_service_account.loki.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/loki]"
  depends_on         = [google_container_cluster.main]
}

# -------------------------
# External Secrets
# -------------------------
resource "google_service_account" "external_secrets" {
  project      = var.project_id
  account_id   = "external-secrets-${var.environment}"
  display_name = "External Secrets - ${var.environment}"
}

resource "google_project_iam_member" "external_secrets_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets.email}"
}

# Workload Identity binding for External Secrets
resource "google_service_account_iam_member" "external_secrets_workload_identity" {
  service_account_id = google_service_account.external_secrets.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets]"
  depends_on         = [google_container_cluster.main]
}

# -------------------------
# ArgoCD (for pulling Helm charts from Artifact Registry)
# -------------------------
resource "google_service_account" "argocd" {
  project      = var.project_id
  account_id   = "argocd-${var.environment}"
  display_name = "ArgoCD - ${var.environment}"
}

resource "google_artifact_registry_repository_iam_member" "argocd_helm_reader" {
  project    = var.shared_project_id
  location   = var.region
  repository = "helm-charts"
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.argocd.email}"
}

# Workload Identity binding for ArgoCD
resource "google_service_account_iam_member" "argocd_workload_identity" {
  service_account_id = google_service_account.argocd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-repo-server]"
  depends_on         = [google_container_cluster.main]
}

# -------------------------
# GitLab CI runner (shared project VM)
# -------------------------
resource "google_project_iam_member" "gitlab_runner_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:206453655812-compute@developer.gserviceaccount.com"
}

# Image updater

resource "google_service_account" "image_updater" {
  project      = var.project_id
  account_id   = "image-updater-${var.environment}"
  display_name = "Argo CD Image Updater - ${var.environment}"
}

resource "google_artifact_registry_repository_iam_member" "image_updater_reader" {
  project    = var.shared_project_id
  location   = var.region
  repository = "containers"
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.image_updater.email}"
}

resource "google_service_account_iam_member" "image_updater_workload_identity" {
  service_account_id = google_service_account.image_updater.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-image-updater]"
  depends_on         = [google_container_cluster.main]
}
