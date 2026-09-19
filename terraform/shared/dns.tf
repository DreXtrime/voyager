resource "google_project_service" "dns" {
  project = var.project_id
  service = "dns.googleapis.com"

  disable_on_destroy = false
}

# Import the existing public DNS zone I created manually
resource "google_dns_managed_zone" "public" {
  project     = var.project_id
  name        = "cloud-tanelneitov-eu"
  dns_name    = "${var.domain}."
  description = "Public DNS zone for cloud.tanelneitov.eu"

  depends_on = [google_project_service.dns]
}

# GitLab DNS record
resource "google_dns_record_set" "gitlab" {
  project      = var.project_id
  name         = "gitlab.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name

  rrdatas = [google_compute_address.gitlab.address]
}
