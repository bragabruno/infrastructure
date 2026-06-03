variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "anthropic_api_key" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

variable "redis_password" {
  type      = string
  sensitive = true
  default   = ""
}
