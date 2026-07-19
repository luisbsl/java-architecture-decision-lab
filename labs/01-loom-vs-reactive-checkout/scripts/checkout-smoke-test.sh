#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8081}"
CORRELATION_ID="${CORRELATION_ID:-smoke-$(date -u +%Y%m%d%H%M%S)}"

response_file="$(mktemp)"
headers_file="$(mktemp)"
trap 'rm -f "${response_file}" "${headers_file}"' EXIT

http_code="$(curl --silent --show-error \
  --output "${response_file}" \
  --dump-header "${headers_file}" \
  --write-out '%{http_code}' \
  -X POST "${BASE_URL}/orders/checkout" \
  -H 'Content-Type: application/json' \
  -H "X-Correlation-Id: ${CORRELATION_ID}" \
  -d '{"orderId":"order-001","customerId":"customer-001","items":[{"sku":"SKU-001","quantity":2,"unitPrice":149.90}],"currency":"BRL"}')"

cat "${response_file}"
echo

if [[ "${http_code}" != "201" ]]; then
  echo "[ERROR] Expected HTTP 201, received ${http_code}" >&2
  exit 1
fi

if ! grep -q '"status":"CONFIRMED"' "${response_file}"; then
  echo "[ERROR] Checkout response was not CONFIRMED" >&2
  exit 1
fi

if ! grep -qi "^X-Correlation-Id: ${CORRELATION_ID}" "${headers_file}"; then
  echo "[ERROR] Correlation ID was not returned" >&2
  exit 1
fi

echo "[OK] Checkout smoke test completed against ${BASE_URL}."
