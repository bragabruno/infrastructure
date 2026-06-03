#!/usr/bin/env bash
set -euo pipefail

DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-fraud_db}
DB_USER=${DB_USER:-fraud_user}
DB_PASSWORD=${DB_PASSWORD:-}

log() { echo "[db-init] $*"; }

export PGPASSWORD="$DB_PASSWORD"

log "Waiting for PostgreSQL at $DB_HOST:$DB_PORT..."
for i in $(seq 1 30); do
  if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" &>/dev/null; then
    log "PostgreSQL is ready"
    break
  fi
  [[ $i -eq 30 ]] && { log "ERROR: PostgreSQL not ready after 60s"; exit 1; }
  sleep 2
done

log "Checking if database '$DB_NAME' exists..."
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
  log "Database '$DB_NAME' already exists"
else
  log "Creating database '$DB_NAME'..."
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME"
  log "Database '$DB_NAME' created"
fi

log "Running Flyway migrations (if backend container available)..."
if command -v docker &>/dev/null && docker compose ps backend &>/dev/null 2>&1; then
  docker compose exec -T backend ./gradlew :app:flywayMigrate -i 2>&1 || log "Flyway migration skipped (backend not ready or already migrated)"
else
  log "Flyway migration skipped (run 'make seed' after backend starts)"
fi

log "Seeding reference data..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<'SQL'
-- Enable uuid extension (gen_random_uuid requires pgcrypto in PG13, built-in in PG16+)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Seed merchants (idempotent)
INSERT INTO merchants (id, name, category, risk_level, country, created_at)
VALUES
  (gen_random_uuid(), 'Amazon', 'electronics', 'LOW', 'US', NOW()),
  (gen_random_uuid(), 'Walmart', 'retail', 'LOW', 'US', NOW()),
  (gen_random_uuid(), 'CryptoExchange XYZ', 'crypto', 'HIGH', 'KY', NOW()),
  (gen_random_uuid(), 'WireTransfer Co', 'wire', 'HIGH', 'NG', NOW()),
  (gen_random_uuid(), 'LocalCoffee', 'food', 'LOW', 'US', NOW())
ON CONFLICT DO NOTHING;

-- Seed devices (idempotent)
INSERT INTO devices (id, device_type, os, browser, is_trusted, created_at)
VALUES
  (gen_random_uuid(), 'desktop', 'macOS', 'Chrome', true, NOW()),
  (gen_random_uuid(), 'mobile', 'iOS', 'Safari', true, NOW()),
  (gen_random_uuid(), 'desktop', 'Windows', 'Firefox', false, NOW()),
  (gen_random_uuid(), 'tablet', 'Android', 'Chrome', false, NOW())
ON CONFLICT DO NOTHING;

-- Seed users (idempotent)
INSERT INTO users (id, email, first_name, last_name, risk_tier, account_created_at, country)
VALUES
  (gen_random_uuid(), 'alice@example.com', 'Alice', 'Smith', 'LOW', '2024-01-15', 'US'),
  (gen_random_uuid(), 'bob@example.com', 'Bob', 'Johnson', 'MEDIUM', '2024-03-20', 'US'),
  (gen_random_uuid(), 'carlos@example.com', 'Carlos', 'Garcia', 'HIGH', '2024-06-01', 'MX'),
  (gen_random_uuid(), 'diana@example.com', 'Diana', 'Chen', 'LOW', '2024-09-10', 'CA'),
  (gen_random_uuid(), 'eve@example.com', 'Eve', 'Kowalski', 'MEDIUM', '2024-11-05', 'UK')
ON CONFLICT DO NOTHING;
SQL

log "Seed data inserted."

log "Database initialization complete."
unset PGPASSWORD
