output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "public_dns_zone" {
  description = "Public DNS zone name"
  value       = google_dns_managed_zone.public.name
}

output "private_dns_zone" {
  description = "Private DNS zone name"
  value       = google_dns_managed_zone.private.name
}

output "db_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.main.name
}

output "db_private_ip" {
  description = "Cloud SQL private IP"
  value       = google_sql_database_instance.main.private_ip_address
  sensitive   = true
}

output "logs_bucket" {
  description = "GCS bucket for logs"
  value       = google_storage_bucket.logs.name
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.main.name
}
