output "bootstrap_brokers" {
  value = aws_msk_cluster.main.bootstrap_brokers_tls
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.main.zookeeper_connect_string
}

output "cluster_arn" {
  value = aws_msk_cluster.main.arn
}

output "cluster_name" {
  value = aws_msk_cluster.main.cluster_name
}
