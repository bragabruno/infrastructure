variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "backend_image" {
  type    = string
  default = "fraudpreventionsystem-backend:latest"
}

variable "ml_service_image" {
  type    = string
  default = "fraudpreventionsystem-ml-service:latest"
}

variable "frontend_image" {
  type    = string
  default = "fraudpreventionsystem-frontend:latest"
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 5
}

variable "cpu_target" {
  type    = number
  default = 70
}

variable "secrets_manager_arns" {
  type    = list(string)
  default = []
}

variable "rds_endpoint" {
  type    = string
  default = ""
}

variable "redis_endpoint" {
  type    = string
  default = ""
}

variable "kafka_brokers" {
  type    = string
  default = ""
}
