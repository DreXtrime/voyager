resource "google_compute_address" "gitlab" {
  project = var.project_id
  name    = "gitlab-ip"
  region  = var.region

  depends_on = [google_project_service.compute]
}

resource "google_compute_disk" "gitlab_data" {
  project = var.project_id
  name    = "gitlab-data"
  type    = "pd-standard"
  zone    = var.zone
  size    = 50

  depends_on = [google_project_service.compute]
}

resource "google_compute_instance" "gitlab" {
  project      = var.project_id
  name         = "gitlab"
  machine_type = var.gitlab_instance_type
  zone         = var.zone

  tags = ["gitlab"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.gitlab_disk_size
      type  = "pd-standard"
    }
  }

  attached_disk {
    source      = google_compute_disk.gitlab_data.id
    device_name = "gitlab-data"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.shared.id

    access_config {
      nat_ip = google_compute_address.gitlab.address
    }
  }

  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      set -e

      # Format and mount data disk if not already mounted
      DATA_DISK="/dev/disk/by-id/google-gitlab-data"
      MOUNT_POINT="/var/opt/gitlab"

      if ! blkid $DATA_DISK; then
        mkfs.ext4 -F $DATA_DISK
      fi

      mkdir -p $MOUNT_POINT
      mount $DATA_DISK $MOUNT_POINT

      # Add to fstab for persistence
      if ! grep -q "gitlab-data" /etc/fstab; then
        echo "$DATA_DISK $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
      fi

      # Install GitLab CE
      apt-get update
      apt-get install -y curl openssh-server ca-certificates tzdata perl

      curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash

      EXTERNAL_URL="https://gitlab.${var.domain}" apt-get install -y gitlab-ce

      gitlab-ctl reconfigure
    EOF
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [google_project_service.compute]
}
