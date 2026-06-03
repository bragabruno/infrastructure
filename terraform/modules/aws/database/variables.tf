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

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention" {
  type    = number
  default = 1
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "fraud_db"
}

variable "db_username" {
  type    = string
  default = "fraud_user"
}
