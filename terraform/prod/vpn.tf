resource "google_compute_address" "vpn" {
  project = var.project_id
  name    = "${var.environment}-vpn-ip"
  region  = var.region

  depends_on = [google_project_service.compute]
}

resource "google_compute_instance" "vpn" {
  project      = var.project_id
  name         = "${var.environment}-vpn"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["vpn"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.vpn.address
    }
  }

  can_ip_forward = true

  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y wireguard

      echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
      sysctl -p

      wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
      chmod 600 /etc/wireguard/server_private.key

      SERVER_PRIVATE=$(cat /etc/wireguard/server_private.key)

      cat > /etc/wireguard/wg0.conf <<WGEOF
[Interface]
Address = 10.200.0.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE
WGEOF

      systemctl enable wg-quick@wg0
      systemctl start wg-quick@wg0
    EOF
  }

  depends_on = [google_project_service.compute]
}

# Firewall rule to allow SSH to VPN VM
resource "google_compute_firewall" "allow_ssh_vpn" {
  project = var.project_id
  name    = "${var.environment}-allow-ssh-vpn"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vpn"]
}

# Firewall rule to allow Wireguard UDP traffic
resource "google_compute_firewall" "allow_wireguard" {
  project = var.project_id
  name    = "${var.environment}-allow-wireguard"
  network = google_compute_network.main.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vpn"]
}

# Firewall rule to allow VPN clients to access internal resources
resource "google_compute_firewall" "allow_vpn_internal" {
  project = var.project_id
  name    = "${var.environment}-allow-vpn-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.200.0.0/24"]
}

output "vpn_ip" {
  description = "Public IP of VPN gateway"
  value       = google_compute_address.vpn.address
}
