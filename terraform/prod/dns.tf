# Public DNS zone for prod environment
resource "google_dns_managed_zone" "public" {
  project     = var.project_id
  name        = "${var.environment}-public"
  dns_name    = "${var.environment}-public.${var.domain}."
  description = "Public DNS zone for ${var.environment} environment"

  depends_on = [google_project_service.dns]
}

# Private DNS zone for prod environment
resource "google_dns_managed_zone" "private" {
  project     = var.project_id
  name        = "${var.environment}-private"
  dns_name    = "${var.environment}-private.${var.domain}."
  description = "Private DNS zone for ${var.environment} environment"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.main.id
    }
  }

  depends_on = [google_project_service.dns]
}

# NS records in shared project to delegate prod-public zone
resource "google_dns_record_set" "env_public_ns" {
  project      = var.shared_project_id
  name         = "${var.environment}-public.${var.domain}."
  type         = "NS"
  ttl          = 300
  managed_zone = "cloud-tanelneitov-eu"

  rrdatas = google_dns_managed_zone.public.name_servers
}

# Database A record in private zone
resource "google_dns_record_set" "db" {
  project      = var.project_id
  name         = "db.${var.environment}-private.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private.name

  rrdatas = [google_sql_database_instance.main.private_ip_address]
}