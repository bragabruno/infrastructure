output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "backend_service_arn" {
  value = aws_ecs_service.backend.id
}

output "ml_service_service_arn" {
  value = aws_ecs_service.ml_service.id
}

output "frontend_service_arn" {
  value = aws_ecs_service.frontend.id
}

output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}
