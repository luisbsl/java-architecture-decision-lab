#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/evidence-common.sh"

IMPLEMENTATION=""
SCENARIO="moderate"
RUN_NUMBER=1
PAIR=1
ORDER=1
WARMUP_SECONDS="${WARMUP_SECONDS:-20}"
KEEP_RUNNING=false
SKIP_BUILD=false
OUT_ROOT="${REPO_ROOT}/.artifacts/evidence"

usage() {
  cat <<'USAGE'
Usage: run-evidence.sh --implementation <mvc-vthreads|webflux-reactor> [options]

Options:
  --scenario <functional|moderate|high|capacity|slow-payment|intermittent-failures>
  --run-number <n>
  --pair <n>
  --order <n>
  --warmup-seconds <n>
  --output-root <path>
  --skip-build
  --keep-running
USAGE
}

while (($#)); do
  case "$1" in
    --implementation) IMPLEMENTATION="${2:?}"; shift 2 ;;
    --scenario) SCENARIO="${2:?}"; shift 2 ;;
    --run-number) RUN_NUMBER="${2:?}"; shift 2 ;;
    --pair) PAIR="${2:?}"; shift 2 ;;
    --order) ORDER="${2:?}"; shift 2 ;;
    --warmup-seconds) WARMUP_SECONDS="${2:?}"; shift 2 ;;
    --output-root) OUT_ROOT="${2:?}"; shift 2 ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    --keep-running) KEEP_RUNNING=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERROR] Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "${IMPLEMENTATION}" ]] || { echo "[ERROR] --implementation is required." >&2; exit 2; }
[[ "${WARMUP_SECONDS}" =~ ^[0-9]+$ ]] || { echo "[ERROR] --warmup-seconds must be a non-negative integer." >&2; exit 2; }
require_command docker
require_command curl
require_command k6
require_command python3
require_command jfr
require_command sha256sum
require_command timeout
docker info >/dev/null
docker compose version >/dev/null
[[ -f "${JFR_PROFILE}" ]] || { echo "[ERROR] Missing JFR profile: ${JFR_PROFILE}" >&2; exit 1; }

git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "[ERROR] Formal evidence requires an initialized Git repository." >&2
  exit 1
}
[[ -z "$(git -C "${REPO_ROOT}" status --porcelain)" ]] || {
  echo "[ERROR] Formal evidence requires a clean worktree." >&2
  exit 1
}
GIT_SHA="$(git -C "${REPO_ROOT}" rev-parse --verify HEAD)"
GIT_BRANCH="$(git -C "${REPO_ROOT}" branch --show-current)"
[[ -n "${GIT_SHA}" ]] || {
  echo "[ERROR] Formal evidence requires a committed Git HEAD." >&2
  exit 1
}

configure_scenario_environment "${SCENARIO}"
SERVICE="$(implementation_service "${IMPLEMENTATION}")"
CONTAINER="$(implementation_container "${IMPLEMENTATION}")"
BASE_URL="$(implementation_base_url "${IMPLEMENTATION}")"
MEASURED_SECONDS="$(scenario_duration_seconds "${SCENARIO}")"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="${TIMESTAMP}-pair$(printf '%02d' "${PAIR}")-order$(printf '%02d' "${ORDER}")-${IMPLEMENTATION}-${SCENARIO}-run${RUN_NUMBER}"
OUT="$(mkdir -p "${OUT_ROOT}" && cd "${OUT_ROOT}" && pwd)/${RUN_ID}"
mkdir -p "${OUT}/load" "${OUT}/warmup" "${OUT}/jfr-reports"
RECORDING_NAME="evidence_${IMPLEMENTATION//-/_}_${SCENARIO//-/_}_${TIMESTAMP}"
JFR_ACTIVE=false
STATS_PID=""
STATS_STOP_FILE="${OUT}/.docker-stats.stop"
STATS_READY_FILE="${OUT}/.docker-stats.ready"
LOAD_RC=0
WORKLOAD_SEED="${WORKLOAD_SEED:-20260718}"
BENCHMARK_LOG_LEVEL="${BENCHMARK_LOG_LEVEL:-WARN}"
SIMULATOR_DETERMINISTIC=true
export WORKLOAD_SEED BENCHMARK_LOG_LEVEL SIMULATOR_DETERMINISTIC
RUNTIME_FINALIZED=false
LOAD_TIMEOUT_SECONDS="${LOAD_TIMEOUT_SECONDS:-$((MEASURED_SECONDS + 90))}"
WARMUP_TIMEOUT_SECONDS="${WARMUP_TIMEOUT_SECONDS:-$((WARMUP_SECONDS + 60))}"

phase() {
  printf '[PHASE] run=%s implementation=%s scenario=%s :: %s\n' \
    "${RUN_ID}" "${IMPLEMENTATION}" "${SCENARIO}" "$1"
}

cleanup() {
  local rc=$?
  trap - EXIT INT TERM
  set +e
  if [[ -n "${STATS_PID}" ]]; then
    : > "${STATS_STOP_FILE}" 2>/dev/null || true
    if kill -0 "${STATS_PID}" 2>/dev/null; then
      wait "${STATS_PID}" 2>/dev/null || true
    fi
  fi
  if [[ "${JFR_ACTIVE}" == "true" ]] && docker inspect "${CONTAINER}" >/dev/null 2>&1; then
    timeout --foreground --signal=TERM --kill-after=5s 30s \
      docker exec --user 10001 "${CONTAINER}" jcmd 1 JFR.stop name="${RECORDING_NAME}" \
      filename="/tmp/${RUN_ID}.jfr" > "${OUT}/jfr-stop-on-exit.txt" 2>&1 || true
    timeout --foreground --signal=TERM --kill-after=5s 30s \
      docker cp "${CONTAINER}:/tmp/${RUN_ID}.jfr" "${OUT}/recording.jfr" >/dev/null 2>&1 || true
  fi
  if [[ "${RUNTIME_FINALIZED}" != "true" ]]; then
    timeout --foreground --signal=TERM --kill-after=5s 30s \
      docker compose -f "${BASE_COMPOSE}" -f "${EVIDENCE_COMPOSE}" ps \
      > "${OUT}/compose-ps-final.txt" 2>&1 || true
    timeout --foreground --signal=TERM --kill-after=5s 30s \
      docker compose -f "${BASE_COMPOSE}" -f "${EVIDENCE_COMPOSE}" logs --no-color \
      > "${OUT}/compose-logs.txt" 2>&1 || true
    timeout --foreground --signal=TERM --kill-after=5s 30s \
      docker inspect "${CONTAINER}" > "${OUT}/container-inspect.json" 2>&1 || true
    if [[ "${KEEP_RUNNING}" != "true" ]]; then
      timeout --foreground --signal=TERM --kill-after=10s 60s \
        docker compose -f "${BASE_COMPOSE}" -f "${EVIDENCE_COMPOSE}" down --remove-orphans \
        > "${OUT}/compose-down.txt" 2>&1 || true
    fi
  fi
  exit "${rc}"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cat > "${OUT}/run.env" <<ENV
RUN_ID=${RUN_ID}
IMPLEMENTATION=${IMPLEMENTATION}
SCENARIO=${SCENARIO}
RUN_NUMBER=${RUN_NUMBER}
PAIR=${PAIR}
ORDER=${ORDER}
GIT_SHA=${GIT_SHA}
GIT_BRANCH=${GIT_BRANCH}
BASE_URL=${BASE_URL}
SERVICE=${SERVICE}
CONTAINER=${CONTAINER}
WARMUP_SECONDS=${WARMUP_SECONDS}
MEASURED_SECONDS=${MEASURED_SECONDS}
LOAD_TIMEOUT_SECONDS=${LOAD_TIMEOUT_SECONDS}
PROTOCOL_FINGERPRINT=${PROTOCOL_FINGERPRINT:-unknown}
APP_CPUS=${APP_CPUS:-2.0}
APP_MEMORY=${APP_MEMORY:-1g}
CUSTOMER_MIN_DELAY=${CUSTOMER_MIN_DELAY}
CUSTOMER_MAX_DELAY=${CUSTOMER_MAX_DELAY}
INVENTORY_MIN_DELAY=${INVENTORY_MIN_DELAY}
INVENTORY_MAX_DELAY=${INVENTORY_MAX_DELAY}
PAYMENT_MIN_DELAY=${PAYMENT_MIN_DELAY}
PAYMENT_MAX_DELAY=${PAYMENT_MAX_DELAY}
PAYMENT_FAILURE_RATE=${PAYMENT_FAILURE_RATE}
DOWNSTREAM_READ_TIMEOUT=${DOWNSTREAM_READ_TIMEOUT}
WORKLOAD_SEED=${WORKLOAD_SEED}
SIMULATOR_DETERMINISTIC=true
BENCHMARK_LOG_LEVEL=${BENCHMARK_LOG_LEVEL}
SIMULATOR_CPUS=${SIMULATOR_CPUS:-2.0}
SIMULATOR_MEMORY=${SIMULATOR_MEMORY:-1g}
ENV

printf '[INFO] run_id=%s\n[INFO] output=%s\n' "${RUN_ID}" "${OUT}"
phase "resetting containers"
timeout --foreground --signal=TERM --kill-after=10s 60s \
  docker compose -f "${BASE_COMPOSE}" -f "${EVIDENCE_COMPOSE}" down --remove-orphans \
  >/dev/null 2>&1 || true

phase "starting simulator and ${SERVICE}"
up_args=(up -d)
[[ "${SKIP_BUILD}" == "true" ]] || up_args+=(--build)
up_args+=(external-services-simulator "${SERVICE}")
compose "${up_args[@]}" | tee "${OUT}/compose-up.txt"

phase "waiting for readiness"
wait_for_http "http://localhost:8083/actuator/health/readiness" 180
wait_for_http "${BASE_URL}/actuator/health/readiness" 180

phase "capturing environment and effective Compose configuration"
IMPLEMENTATION="${IMPLEMENTATION}" SCENARIO="${SCENARIO}" RUN_NUMBER="${RUN_NUMBER}" \
RUN_ID="${RUN_ID}" OUT="${OUT}" FORMAL_RUN=true \
  "${SCRIPT_DIR}/capture-environment.sh" >/dev/null
compose config > "${OUT}/docker-compose-effective.yml"
compose ps > "${OUT}/compose-ps-start.txt"

# Fixed warm-up is not part of the measured summary.
if (( WARMUP_SECONDS > 0 )); then
  phase "warm-up ${WARMUP_SECONDS}s (not included in measured results)"
  timeout --foreground --signal=TERM --kill-after=10s "${WARMUP_TIMEOUT_SECONDS}s" \
    env IMPLEMENTATION="${IMPLEMENTATION}" SCENARIO=moderate BASE_URL="${BASE_URL}" \
    RATE="${WARMUP_RATE:-5}" DURATION="${WARMUP_SECONDS}s" PRE_ALLOCATED_VUS=10 MAX_VUS=30 \
    RUN_ID="${RUN_ID}-warmup" OUT="${OUT}/warmup" MEASURED_RUN=false K6_RAW_OUTPUT=false \
    PAIR="${PAIR}" WORKLOAD_SEED="${WORKLOAD_SEED}" \
    "${SCRIPT_DIR}/run-load-test.sh" > "${OUT}/warmup-console.txt" 2>&1
fi

phase "capturing pre-load Actuator and JVM snapshots"
BASE_URL="${BASE_URL}" OUT="${OUT}" PHASE=before "${SCRIPT_DIR}/capture-actuator.sh"
IMPLEMENTATION="${IMPLEMENTATION}" OUT="${OUT}" PHASE=before "${SCRIPT_DIR}/capture-container-jvm.sh"

phase "starting lifecycle-controlled Docker stats capture"
rm -f "${STATS_STOP_FILE}" "${STATS_READY_FILE}"
OUT="${OUT}" SAMPLES=0 INTERVAL_SECONDS=2 \
STOP_FILE="${STATS_STOP_FILE}" READY_FILE="${STATS_READY_FILE}" \
  "${SCRIPT_DIR}/capture-docker-stats.sh" > "${OUT}/docker-stats-console.txt" 2>&1 &
STATS_PID=$!
for _ in {1..100}; do
  [[ -e "${STATS_READY_FILE}" ]] && break
  kill -0 "${STATS_PID}" 2>/dev/null || {
    echo "[ERROR] Docker stats collector exited before readiness." >&2
    exit 1
  }
  sleep 0.1
done
[[ -e "${STATS_READY_FILE}" ]] || {
  echo "[ERROR] Docker stats collector did not become ready." >&2
  exit 1
}

phase "starting JFR recording"
docker cp "${JFR_PROFILE}" "${CONTAINER}:/tmp/evidence-profile.jfc"
jcmd_container "${CONTAINER}" JFR.start \
  name="${RECORDING_NAME}" settings=/tmp/evidence-profile.jfc disk=true maxsize=250m \
  > "${OUT}/jfr-start.txt"
JFR_ACTIVE=true
jcmd_container "${CONTAINER}" JFR.check > "${OUT}/jfr-check-before.txt"

phase "measured k6 load ${MEASURED_SECONDS}s (watchdog ${LOAD_TIMEOUT_SECONDS}s)"
wrapper_start_ns="$(date +%s%N)"
set +e
timeout --foreground --signal=TERM --kill-after=20s "${LOAD_TIMEOUT_SECONDS}s" \
  env IMPLEMENTATION="${IMPLEMENTATION}" SCENARIO="${SCENARIO}" BASE_URL="${BASE_URL}" \
  RUN_ID="${RUN_ID}" OUT="${OUT}/load" MEASURED_RUN=true K6_RAW_OUTPUT=true \
  DURATION="${MEASURED_SECONDS}s" PAIR="${PAIR}" WORKLOAD_SEED="${WORKLOAD_SEED}" \
  "${SCRIPT_DIR}/run-load-test.sh"
LOAD_RC=$?
set -e
wrapper_end_ns="$(date +%s%N)"
load_env="${OUT}/load/load-test.env"
start_ns="$(awk -F= '$1=="K6_STARTED_NS" {print $2}' "${load_env}" 2>/dev/null || true)"
end_ns="$(awk -F= '$1=="K6_ENDED_NS" {print $2}' "${load_env}" 2>/dev/null || true)"
[[ "${start_ns}" =~ ^[0-9]+$ ]] || start_ns="${wrapper_start_ns}"
[[ "${end_ns}" =~ ^[0-9]+$ ]] || end_ns="${wrapper_end_ns}"
echo "measured_start_ns=${start_ns}" >> "${OUT}/run.env"
echo "measured_end_ns=${end_ns}" >> "${OUT}/run.env"
echo "wrapper_start_ns=${wrapper_start_ns}" >> "${OUT}/run.env"
echo "wrapper_end_ns=${wrapper_end_ns}" >> "${OUT}/run.env"
echo "k6_exit_code=${LOAD_RC}" >> "${OUT}/run.env"

phase "stopping JFR at the measured-load boundary"
jcmd_container "${CONTAINER}" JFR.stop name="${RECORDING_NAME}" \
  filename="/tmp/${RUN_ID}.jfr" > "${OUT}/jfr-stop.txt"
JFR_ACTIVE=false
docker cp "${CONTAINER}:/tmp/${RUN_ID}.jfr" "${OUT}/recording.jfr"

phase "stopping Docker stats capture and joining collector"
: > "${STATS_STOP_FILE}"
wait "${STATS_PID}"
STATS_PID=""
rm -f "${STATS_STOP_FILE}" "${STATS_READY_FILE}"

phase "collecting post-load evidence"
BASE_URL="${BASE_URL}" OUT="${OUT}" PHASE=after "${SCRIPT_DIR}/capture-actuator.sh"
IMPLEMENTATION="${IMPLEMENTATION}" OUT="${OUT}" PHASE=after "${SCRIPT_DIR}/capture-container-jvm.sh"
"${SCRIPT_DIR}/render-jfr-reports.sh" "${OUT}/recording.jfr" "${OUT}/jfr-reports"
compose ps > "${OUT}/compose-ps-final.txt"
compose logs --no-color > "${OUT}/compose-logs.txt"
docker inspect "${CONTAINER}" > "${OUT}/container-inspect.json"
if [[ "${KEEP_RUNNING}" != "true" ]]; then
  timeout --foreground --signal=TERM --kill-after=10s 60s \
    docker compose -f "${BASE_COMPOSE}" -f "${EVIDENCE_COMPOSE}" down --remove-orphans \
    > "${OUT}/compose-down.txt" 2>&1
fi
RUNTIME_FINALIZED=true

if [[ -f "${OUT}/load/k6-summary.json" ]]; then
  phase "building normalized summary and integrity manifest"
  python3 "${SCRIPT_DIR}/build-run-summary.py" "${OUT}" > "${OUT}/run-summary-console.json"
else
  cat > "${OUT}/RUN_FAILED.md" <<FAIL
# Evidence Run Failed

- Run: ${RUN_ID}
- k6 exit code: ${LOAD_RC}
- Expected summary was not produced: load/k6-summary.json
- Evidence and cleanup diagnostics were preserved.
FAIL
fi
(
  cd "${OUT}"
  find . -type f ! -name manifest.sha256 -print0 | sort -z | xargs -0 sha256sum > manifest.sha256
  sleep 1
  sha256sum --check --strict manifest.sha256 >/dev/null
)

if (( LOAD_RC == 124 || LOAD_RC == 137 )); then
  echo "[ERROR] Measured k6 phase exceeded its ${LOAD_TIMEOUT_SECONDS}s watchdog; evidence was preserved." >&2
  exit 124
elif (( LOAD_RC != 0 )); then
  echo "[ERROR] k6 thresholds or execution failed; evidence was preserved." >&2
  exit "${LOAD_RC}"
fi

cat <<RESULT
[OK] Evidence run completed.
RUN_ID=${RUN_ID}
OUT=${OUT}
K6_EXIT_CODE=${LOAD_RC}
SUMMARY=${OUT}/RUN_SUMMARY.md
RESULT
