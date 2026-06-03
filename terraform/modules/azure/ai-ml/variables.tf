variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "openai_sku" {
  type    = string
  default = "S0"
}

variable "gpt4_deployment_name" {
  type    = string
  default = "gpt-4"
}

variable "gpt4_model_version" {
  type    = string
  default = "0125-Preview"
}

variable "gpt4_capacity" {
  type    = number
  default = 10
}
