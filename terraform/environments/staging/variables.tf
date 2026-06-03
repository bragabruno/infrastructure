variable "project_name" {
  type    = string
  default = "fraud-prevention"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "aws_azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "gcp_project_id" {
  type = string
}

variable "google_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_region" {
  type    = string
  default = "eastus"
}

variable "azure_resource_group_name" {
  type = string
}
