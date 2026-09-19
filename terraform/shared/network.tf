resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_compute_network" "shared" {
  project                 = var.project_id
  name                    = "shared-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "shared" {
  project       = var.project_id
  name          = "shared-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.shared.id
}

# Allow SSH to GitLab VM from anywhere
resource "google_compute_firewall" "allow_ssh" {
  project = var.project_id
  name    = "shared-allow-ssh"
  network = google_compute_network.shared.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitlab"]
}

# Allow HTTP and HTTPS to GitLab VM
resource "google_compute_firewall" "allow_http_https" {
  project = var.project_id
  name    = "shared-allow-http-https"
  network = google_compute_network.shared.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitlab"]
}

# Allow internal traffic within the VPC
resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "shared-allow-internal"
  network = google_compute_network.shared.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/24"]
}
