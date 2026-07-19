#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd -- "${LAB_DIR}/../.." && pwd)"
BASE_COMPOSE="${LAB_DIR}/docker-compose.yml"
EVIDENCE_COMPOSE="${LAB_DIR}/docker-compose.evidence.yml"
JFR_PROFILE="${REPO_ROOT}/docs/profiling/evidence-profile.jfc"

compose() {
  docker compose -f "${BASE_COMPOSE}" -f "${EVIDENCE_COMPOSE}" "$@"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERROR] Required command not found: $1" >&2
    exit 1
  }
}

implementation_service() {
  case "$1" in
    mvc-vthreads) echo "mvc-virtual-threads" ;;
    webflux-reactor) echo "webflux-reactor" ;;
    *) echo "[ERROR] Unsupported implementation: $1" >&2; return 2 ;;
  esac
}

implementation_container() {
  case "$1" in
    mvc-vthreads) echo "arch-lab-mvc-virtual-threads" ;;
    webflux-reactor) echo "arch-lab-webflux-reactor" ;;
    *) echo "[ERROR] Unsupported implementation: $1" >&2; return 2 ;;
  esac
}

implementation_base_url() {
  case "$1" in
    mvc-vthreads) echo "http://localhost:8081" ;;
    webflux-reactor) echo "http://localhost:8082" ;;
    *) echo "[ERROR] Unsupported implementation: $1" >&2; return 2 ;;
  esac
}

scenario_duration_seconds() {
  case "$1" in
    functional) echo 1 ;;
    moderate) echo "${DURATION_SECONDS:-60}" ;;
    high|capacity) echo "${DURATION_SECONDS:-120}" ;;
    slow-payment|intermittent-failures) echo "${DURATION_SECONDS:-60}" ;;
    *) echo "[ERROR] Unsupported scenario: $1" >&2; return 2 ;;
  esac
}

configure_scenario_environment() {
  local scenario="$1"
  export CUSTOMER_FAILURE_RATE=0.00
  export INVENTORY_FAILURE_RATE=0.00
  export PAYMENT_FAILURE_RATE=0.00
  export CUSTOMER_MIN_DELAY=80ms
  export CUSTOMER_MAX_DELAY=150ms
  export INVENTORY_MIN_DELAY=100ms
  export INVENTORY_MAX_DELAY=250ms
  export PAYMENT_MIN_DELAY=150ms
  export PAYMENT_MAX_DELAY=400ms
  export DOWNSTREAM_READ_TIMEOUT=2s

  case "${scenario}" in
    functional|moderate|high|capacity) ;;
    slow-payment)
      export PAYMENT_MIN_DELAY="${PAYMENT_MIN_DELAY_OVERRIDE:-1200ms}"
      export PAYMENT_MAX_DELAY="${PAYMENT_MAX_DELAY_OVERRIDE:-1800ms}"
      export DOWNSTREAM_READ_TIMEOUT="${DOWNSTREAM_READ_TIMEOUT_OVERRIDE:-3s}"
      ;;
    intermittent-failures)
      export PAYMENT_FAILURE_RATE="${PAYMENT_FAILURE_RATE_OVERRIDE:-0.15}"
      ;;
    *)
      echo "[ERROR] Unsupported scenario: ${scenario}" >&2
      return 2
      ;;
  esac
}

wait_for_http() {
  local url="$1"
  local timeout_seconds="${2:-120}"
  local started
  started="$(date +%s)"
  until curl --fail --silent --show-error "${url}" >/dev/null 2>&1; do
    if (( $(date +%s) - started >= timeout_seconds )); then
      echo "[ERROR] Timed out waiting for ${url}" >&2
      return 1
    fi
    sleep 2
  done
  echo "[OK] Ready: ${url}"
}

jcmd_container() {
  local container="$1"
  shift
  docker exec --user 10001 "${container}" jcmd 1 "$@"
}
