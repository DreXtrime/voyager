# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  project      = var.project_id
  account_id   = "${var.environment}-gke-nodes"
  display_name = "GKE Nodes Service Account - ${var.environment}"
}

# Minimal permissions for GKE nodes
resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Allow nodes to pull from shared artifact registry
resource "google_artifact_registry_repository_iam_member" "gke_nodes_reader" {
  project    = var.shared_project_id
  location   = var.region
  repository = "containers"
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# GKE Cluster
resource "google_container_cluster" "main" {
  project  = var.project_id
  name     = "${var.environment}-cluster"
  location = var.region

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.main.name

  # Private cluster config
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  depends_on = [
    google_project_service.container,
    google_compute_subnetwork.main
  ]
}

# Main node pool - for sample application
resource "google_container_node_pool" "main" {
  project    = var.project_id
  name       = "main"
  location   = var.region
  cluster    = google_container_cluster.main.name
  node_count = var.main_node_count
  node_locations = ["europe-north1-a", "europe-north1-b", "europe-north1-c"]

  node_config {
    machine_type    = var.node_machine_type
    disk_type       = "pd-standard"
    disk_size_gb    = 30
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      pool        = "main"
      environment = var.environment
    }

    taint {
      key    = "pool"
      value  = "main"
      effect = "NO_SCHEDULE"
    }
  }
}

# Tools node pool - for ArgoCD, External DNS, External Secrets
resource "google_container_node_pool" "tools" {
  project    = var.project_id
  name       = "tools"
  location   = var.region
  cluster    = google_container_cluster.main.name
  node_count = var.tools_node_count

  node_config {
    machine_type    = var.node_machine_type
    disk_type       = "pd-standard"
    disk_size_gb    = 30
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      pool        = "tools"
      environment = var.environment
    }
  }
}

# Monitoring node pool - for Prometheus, Loki, Grafana
resource "google_container_node_pool" "monitoring" {
  project    = var.project_id
  name       = "monitoring"
  location   = var.region
  cluster    = google_container_cluster.main.name
  node_count = var.monitoring_node_count

  node_config {
    machine_type    = var.node_machine_type
    disk_type       = "pd-standard"
    disk_size_gb    = 30
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      pool        = "monitoring"
      environment = var.environment
    }

    taint {
      key    = "pool"
      value  = "monitoring"
      effect = "NO_SCHEDULE"
    }
  }
}
