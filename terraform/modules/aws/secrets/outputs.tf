output "secret_arns" {
  value = {
    postgres_password  = aws_secretsmanager_secret.postgres_password.arn
    jwt_secret         = aws_secretsmanager_secret.jwt_secret.arn
    anthropic_api_key  = aws_secretsmanager_secret.anthropic_api_key.arn
    redis_password     = aws_secretsmanager_secret.redis_password.arn
  }
}

output "secret_names" {
  value = {
    postgres_password  = aws_secretsmanager_secret.postgres_password.name
    jwt_secret         = aws_secretsmanager_secret.jwt_secret.name
    anthropic_api_key  = aws_secretsmanager_secret.anthropic_api_key.name
    redis_password     = aws_secretsmanager_secret.redis_password.name
  }
}
