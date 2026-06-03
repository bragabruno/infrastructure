variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "fraud-prevention"
}

# AWS
variable "aws_region" {
  description = "AWS region for primary infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_azs" {
  description = "AWS availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# GCP
variable "gcp_project_id" {
  description = "GCP project ID for Firebase Auth"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

# Azure
variable "azure_subscription_id" {
  description = "Azure subscription ID for AI/ML services"
  type        = string
}

variable "azure_region" {
  description = "Azure region for AI/ML services"
  type        = string
  default     = "eastus"
}

variable "azure_resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = "fraud-prevention-rg"
}

# Sizing
variable "instance_size" {
  description = "Instance size tier (small, medium, large)"
  type        = string
  default     = "small"
}

variable "multi_az" {
  description = "Enable multi-AZ for HA"
  type        = bool
  default     = false
}

variable "backup_retention" {
  description = "Backup retention period in days"
  type        = number
  default     = 1
}
