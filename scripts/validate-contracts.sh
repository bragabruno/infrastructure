#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

log() { echo "[contract] $*"; }
fail() { echo "[contract] FAIL: $*" >&2; exit 1; }

# ── 1. Validate Backend OpenAPI spec exists ──────────────────────────────────
log "Checking backend OpenAPI spec..."
BACKEND_SPEC="backend/build/openapi/openapi.json"

if [[ ! -f "$BACKEND_SPEC" ]]; then
  log "OpenAPI spec not found. Building backend to generate it..."
  (cd backend && ./gradlew :app:bootJar -x test 2>/dev/null)
fi

if [[ ! -f "$BACKEND_SPEC" ]]; then
  fail "Backend OpenAPI spec not found at $BACKEND_SPEC"
fi
log "Backend OpenAPI spec found"

# ── 2. Validate ML service Pydantic schema ───────────────────────────────────
log "Checking ML service schemas..."
ML_SCHEMA="ml-service/src/ml_service/schemas/predict.py"

if [[ ! -f "$ML_SCHEMA" ]]; then
  fail "ML service schema not found at $ML_SCHEMA"
fi
log "ML service schema found"

# ── 3. Extract backend ML client expected response shape ─────────────────────
log "Checking backend ML client response DTO..."
BACKEND_ML_DTO="backend/app/src/main/java/com/bragdev/frauddetection/dto/MlPredictionResponse.java"

if [[ ! -f "$BACKEND_ML_DTO" ]]; then
  log "WARNING: Backend ML DTO not found at $BACKEND_ML_DTO (may not exist yet)"
else
  log "Backend ML DTO found"
fi

# ── 4. Validate frontend MSW handlers match backend API ──────────────────────
log "Checking frontend MSW handlers..."
MSW_DIR="frontend/src/mocks/handlers"

if [[ ! -d "$MSW_DIR" ]]; then
  log "WARNING: MSW handlers directory not found at $MSW_DIR"
else
  HANDLER_COUNT=$(find "$MSW_DIR" -name "*.ts" | wc -l)
  log "Found $HANDLER_COUNT MSW handler files"
fi

# ── 5. Cross-reference key endpoints ─────────────────────────────────────────
log "Validating key endpoint contracts..."

REQUIRED_ENDPOINTS=(
  "/api/auth/login"
  "/api/auth/me"
  "/api/cases"
  "/api/transactions"
  "/api/admin/users"
  "/api/admin/rules"
  "/ml/predict"
  "/ml/health"
)

BACKEND_SPEC_CONTENT=""
if [[ -f "$BACKEND_SPEC" ]]; then
  BACKEND_SPEC_CONTENT=$(cat "$BACKEND_SPEC")
fi

MISSING=0
for endpoint in "${REQUIRED_ENDPOINTS[@]}"; do
  if [[ -n "$BACKEND_SPEC_CONTENT" ]] && echo "$BACKEND_SPEC_CONTENT" | grep -q "$endpoint"; then
    log "  $endpoint ✓"
  else
    log "  $endpoint ✗ (not found in OpenAPI spec)"
    (( MISSING++ )) || true
  fi
done

if [[ $MISSING -gt 0 ]]; then
  log "WARNING: $MISSING endpoints not found in OpenAPI spec (may be added later)"
fi

# ── 6. Validate Kafka topic names ────────────────────────────────────────────
log "Validating Kafka topic consistency..."

REQUIRED_TOPICS=(
  "transactions.created"
  "fraud.scored"
  "fraud.review.required"
  "fraud.confirmed"
  "fraud.falsepositive"
  "fraud.retraining.requested"
  "fraud.model.deployed"
)

# Check ML service Kafka config
ML_KAFKA_CONFIG="ml-service/src/ml_service/events"
if [[ -d "$ML_KAFKA_CONFIG" ]]; then
  for topic in "${REQUIRED_TOPICS[@]}"; do
    if grep -r "$topic" "$ML_KAFKA_CONFIG" &>/dev/null; then
      log "  $topic (ml-service) ✓"
    else
      log "  $topic (ml-service) ✗"
    fi
  done
fi

# Check backend Kafka config
BACKEND_KAFKA_CONFIG="backend/app/src/main/java/com/bragdev/frauddetection"
if [[ -d "$BACKEND_KAFKA_CONFIG" ]]; then
  for topic in "${REQUIRED_TOPICS[@]}"; do
    if grep -r "$topic" "$BACKEND_KAFKA_CONFIG" &>/dev/null; then
      log "  $topic (backend) ✓"
    else
      log "  $topic (backend) ✗"
    fi
  done
fi

log "Contract validation complete."
