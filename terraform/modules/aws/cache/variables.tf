variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "data_security_group_id" {
  type = string
}

variable "node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "num_cache_nodes" {
  type    = number
  default = 1
}

variable "engine_version" {
  type    = string
  default = "7.0"
}
