variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "messaging_security_group_id" {
  type = string
}

variable "number_of_broker_nodes" {
  type    = number
  default = 1
}

variable "kafka_version" {
  type    = string
  default = "3.6.0"
}

variable "instance_type" {
  type    = string
  default = "kafka.t3.small"
}

variable "topics" {
  type = list(string)
  default = [
    "transactions.created",
    "fraud.scored",
    "fraud.review.required",
    "fraud.confirmed",
    "fraud.falsepositive",
    "fraud.retraining.requested",
    "fraud.model.deployed"
  ]
}

variable "partitions_per_topic" {
  type    = number
  default = 1
}
