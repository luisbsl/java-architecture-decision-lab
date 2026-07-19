#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:?Set BASE_URL}"
OUT="${OUT:?Set OUT to an evidence directory}"
PHASE="${PHASE:-snapshot}"
mkdir -p "${OUT}"

capture_required() {
  local endpoint="$1" file="$2"
  curl --fail --silent --show-error "${BASE_URL}${endpoint}" > "${OUT}/${PHASE}-${file}"
}

capture_optional() {
  local endpoint="$1" file="$2"
  curl --fail --silent --show-error "${BASE_URL}${endpoint}" \
    > "${OUT}/${PHASE}-${file}" 2> "${OUT}/${PHASE}-${file}.error" || true
  [[ -s "${OUT}/${PHASE}-${file}.error" ]] || rm -f "${OUT}/${PHASE}-${file}.error"
}

capture_required /actuator/health health.json
capture_required /actuator/health/liveness liveness.json
capture_required /actuator/health/readiness readiness.json
capture_required /actuator/info info.json
capture_required /actuator/prometheus prometheus.txt
capture_required /actuator/metrics metrics-index.json

for metric in \
  process.cpu.usage system.cpu.usage process.uptime \
  jvm.memory.used jvm.memory.committed jvm.memory.max \
  jvm.threads.live jvm.threads.peak jvm.threads.daemon \
  jvm.gc.pause http.server.requests checkout.duration; do
  capture_optional "/actuator/metrics/${metric}" "metric-${metric}.json"
done

echo "[OK] Actuator snapshot '${PHASE}' captured in ${OUT}."
