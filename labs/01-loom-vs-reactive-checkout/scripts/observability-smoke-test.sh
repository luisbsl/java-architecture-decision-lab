#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:?Set BASE_URL to the application under test}"
CORRELATION_ID="${CORRELATION_ID:-observability-smoke}"

for endpoint in health info prometheus; do
  echo "[SMOKE] ${BASE_URL}/actuator/${endpoint}"
  curl --fail --silent --show-error "${BASE_URL}/actuator/${endpoint}" >/dev/null
done

headers="$(mktemp)"
trap 'rm -f "${headers}"' EXIT
curl --fail --silent --show-error --output /dev/null --dump-header "${headers}" \
  -X POST "${BASE_URL}/orders/checkout" \
  -H 'Content-Type: application/json' \
  -H "X-Correlation-Id: ${CORRELATION_ID}" \
  -d '{"orderId":"obs-order-001","customerId":"customer-001","items":[{"sku":"SKU-001","quantity":1,"unitPrice":149.90}],"currency":"BRL"}'

if ! grep -qi "^X-Correlation-Id: ${CORRELATION_ID}" "${headers}"; then
  echo "[ERROR] Correlation ID was not returned by ${BASE_URL}" >&2
  exit 1
fi

echo "[OK] Observability contract validated for ${BASE_URL}."
