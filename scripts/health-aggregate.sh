#!/usr/bin/env bash
set -euo pipefail

BACKEND_URL=${BACKEND_URL:-http://localhost:8080}
ML_URL=${ML_URL:-http://localhost:8001}
FRONTEND_URL=${FRONTEND_URL:-http://localhost:4200}
MLFLOW_URL=${MLFLOW_URL:-http://localhost:5001}

PASS=0
FAIL=0
TOTAL_MS=0

check() {
  local name=$1 url=$2
  local start_ms=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
  if curl -sf --max-time 5 "$url" &>/dev/null; then
    local end_ms=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
    local ms=$(( end_ms - start_ms ))
    TOTAL_MS=$(( TOTAL_MS + ms ))
    printf "  %-20s UP     (%dms)\n" "$name" "$ms"
    (( PASS++ )) || true
    return 0
  else
    printf "  %-20s DOWN\n" "$name"
    (( FAIL++ )) || true
    return 1
  fi
}

echo "═══════════════════════════════════════════════════"
echo "  Fraud Prevention Platform — Health Check"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════"
echo ""

check "backend"     "$BACKEND_URL/actuator/health"
check "ml-service"  "$ML_URL/health"
check "frontend"    "$FRONTEND_URL"
check "mlflow"      "$MLFLOW_URL/health"

echo ""
echo "───────────────────────────────────────────────────"
echo "  $PASS healthy / $FAIL unhealthy"
echo "  Total latency: ${TOTAL_MS}ms"
echo "───────────────────────────────────────────────────"

if [[ $FAIL -eq 0 ]]; then
  echo "  Status: ALL SYSTEMS OPERATIONAL"
  exit 0
else
  echo "  Status: DEGRADED ($FAIL service(s) down)"
  exit 1
fi
