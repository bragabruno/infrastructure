resource "aws_secretsmanager_secret" "postgres_password" {
  name                    = "${var.project_name}/${var.environment}/POSTGRES_PASSWORD"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres-password"
  }
}

resource "aws_secretsmanager_secret_version" "postgres_password" {
  secret_id     = aws_secretsmanager_secret.postgres_password.id
  secret_string = var.db_password

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "${var.project_name}/${var.environment}/JWT_SECRET"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.jwt_secret != "" ? var.jwt_secret : random_password.jwt.result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "anthropic_api_key" {
  name                    = "${var.project_name}/${var.environment}/ANTHROPIC_API_KEY"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-anthropic-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "anthropic_api_key" {
  secret_id     = aws_secretsmanager_secret.anthropic_api_key.id
  secret_string = var.anthropic_api_key

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "redis_password" {
  name                    = "${var.project_name}/${var.environment}/REDIS_PASSWORD"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-password"
  }
}

resource "aws_secretsmanager_secret_version" "redis_password" {
  secret_id     = aws_secretsmanager_secret.redis_password.id
  secret_string = var.redis_password != "" ? var.redis_password : random_password.redis.result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "random_password" "redis" {
  length  = 32
  special = false
}
