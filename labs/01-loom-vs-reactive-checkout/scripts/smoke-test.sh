#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8083}"

request() {
  local label="$1"
  shift
  echo
  echo "[SMOKE] ${label}"
  curl --fail --silent --show-error "$@"
  echo
}

request "Simulator status" "${BASE_URL}/api/simulator/status"
request "Customer lookup" "${BASE_URL}/api/customers/customer-001"
request "Inventory check" "${BASE_URL}/api/inventory/SKU-001?quantity=2"
request "Payment authorization" \
  -X POST "${BASE_URL}/api/payments/authorize" \
  -H 'Content-Type: application/json' \
  -d '{"orderId":"order-001","customerId":"customer-001","amount":149.90,"currency":"BRL"}'

echo
echo "[OK] Baseline smoke test completed."
