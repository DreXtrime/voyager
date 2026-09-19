# Public DNS zone for test environment
resource "google_dns_managed_zone" "public" {
  project     = var.project_id
  name        = "test-public"
  dns_name    = "test-public.${var.domain}."
  description = "Public DNS zone for test environment"

  depends_on = [google_project_service.dns]
}

# Private DNS zone for test environment
resource "google_dns_managed_zone" "private" {
  project     = var.project_id
  name        = "test-private"
  dns_name    = "test-private.${var.domain}."
  description = "Private DNS zone for test environment"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.main.id
    }
  }

  depends_on = [google_project_service.dns]
}

# NS records in shared project to delegate test-public zone
resource "google_dns_record_set" "test_public_ns" {
  project      = var.shared_project_id
  name         = "test-public.${var.domain}."
  type         = "NS"
  ttl          = 300
  managed_zone = "cloud-tanelneitov-eu"

  rrdatas = google_dns_managed_zone.public.name_servers
}

# Database A record in private zone
resource "google_dns_record_set" "db" {
  project      = var.project_id
  name         = "db.test-private.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private.name

  rrdatas = [google_sql_database_instance.main.private_ip_address]
}
