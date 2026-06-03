output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "data_security_group_id" {
  value = aws_security_group.data.id
}

output "messaging_security_group_id" {
  value = aws_security_group.messaging.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "nat_gateway_ip" {
  value = aws_eip.nat[0].public_ip
}
