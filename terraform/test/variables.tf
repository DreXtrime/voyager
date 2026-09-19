variable "project_id" {
  description = "GCP project ID for test environment"
  type        = string
  default     = "tanel-test-509115"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-north1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-north1-a"
}

variable "domain" {
  description = "Root domain"
  type        = string
  default     = "cloud.tanelneitov.eu"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "shared_project_id" {
  description = "Shared GCP project ID"
  type        = string
  default     = "tanel-shared"
}

# VPC
variable "vpc_cidr" {
  description = "VPC subnet CIDR"
  type        = string
  default     = "10.1.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range for GKE pods"
  type        = string
  default     = "10.1.16.0/20"
}

variable "services_cidr" {
  description = "Secondary range for GKE services"
  type        = string
  default     = "10.1.32.0/20"
}

# GKE
variable "gke_version" {
  description = "GKE version"
  type        = string
  default     = "latest"
}

variable "main_node_count" {
  description = "Number of nodes in main pool"
  type        = number
  default     = 1
}

variable "tools_node_count" {
  description = "Number of nodes in tools pool"
  type        = number
  default     = 1
}

variable "monitoring_node_count" {
  description = "Number of nodes in monitoring pool"
  type        = number
  default     = 1
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

# Database
variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "sampleapp"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "sampleapp"
}
