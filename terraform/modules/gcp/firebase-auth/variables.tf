variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "gcp_project_id" {
  type = string
}

variable "google_oauth_client_id" {
  type        = string
  description = "Google OAuth client ID for social login"
  sensitive   = true
}

variable "google_oauth_client_secret" {
  type        = string
  description = "Google OAuth client secret for social login"
  sensitive   = true
}
