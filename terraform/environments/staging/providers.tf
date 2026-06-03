terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project     = var.project_name
      environment = "staging"
      managed_by  = "terraform"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = "us-central1"
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
