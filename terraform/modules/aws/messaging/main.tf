resource "aws_msk_configuration" "main" {
  name = "${var.project_name}-${var.environment}-config"

  kafka_versions = [var.kafka_version]

  server_properties = <<PROPERTIES
auto.create.topics.enable=true
default.replication.factor=${min(var.number_of_broker_nodes, 2)}
min.insync.replicas=${min(var.number_of_broker_nodes, 2)}
num.partitions=${var.partitions_per_topic}
PROPERTIES
}

resource "aws_cloudwatch_log_group" "msk" {
  name              = "/msk/${var.project_name}-${var.environment}"
  retention_in_days = 30
}

resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.project_name}-${var.environment}"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type  = var.instance_type
    client_subnets = slice(var.private_subnet_ids, 0, var.number_of_broker_nodes)
    security_groups = [var.messaging_security_group_id]

    storage_info {
      ebs_storage_info {
        volume_size = 100
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-msk"
  }
}
