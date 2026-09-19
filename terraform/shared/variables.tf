variable "project_id" {
  description = "GCP project ID for shared resources"
  type        = string
  default     = "tanel-shared"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-north1"
}

variable "zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "europe-north1-a"
}

variable "domain" {
  description = "Root domain for the project"
  type        = string
  default     = "cloud.tanelneitov.eu"
}

variable "gitlab_instance_type" {
  description = "Machine type for GitLab VM"
  type        = string
  default     = "e2-standard-2"
}

variable "gitlab_disk_size" {
  description = "Boot disk size in GB for GitLab VM"
  type        = number
  default     = 50
}

variable "test_project_id" {
  description = "GCP project ID for test environment"
  type        = string
  default     = "tanel-test-509115"
}

variable "prod_project_id" {
  description = "GCP project ID for prod environment"
  type        = string
  default     = "tanel-prod"
}
