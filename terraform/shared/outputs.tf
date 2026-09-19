output "artifact_registry_repository_frontend" {
  description = "Artifact Registry repository URL for frontend"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}/frontend"
}

output "artifact_registry_repository_backend" {
  description = "Artifact Registry repository URL for backend"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}/backend"
}

output "artifact_registry_helm_url" {
  description = "Artifact Registry OCI URL for Helm charts"
  value       = "oci://${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.helm_charts.repository_id}"
}

output "gitlab_ip" {
  description = "Public IP address of GitLab VM"
  value       = google_compute_instance.gitlab.network_interface[0].access_config[0].nat_ip
}

output "gitlab_url" {
  description = "GitLab URL"
  value       = "https://gitlab.${var.domain}"
}
