#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${SCENARIO:-functional}"
IMPLEMENTATION="${IMPLEMENTATION:-mvc-vthreads}"
MEASURED_RUN="${MEASURED_RUN:-false}"
K6_RAW_OUTPUT="${K6_RAW_OUTPUT:-false}"
HEARTBEAT_SECONDS="${HEARTBEAT_SECONDS:-15}"
PAIR="${PAIR:-0}"
WORKLOAD_SEED="${WORKLOAD_SEED:-20260718}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
LAB="${ROOT}/labs/01-loom-vs-reactive-checkout"

case "${IMPLEMENTATION}" in
  mvc-vthreads) BASE_URL="${BASE_URL:-http://localhost:8081}" ;;
  webflux-reactor) BASE_URL="${BASE_URL:-http://localhost:8082}" ;;
  *) echo "[ERROR] Unsupported IMPLEMENTATION: ${IMPLEMENTATION}" >&2; exit 2 ;;
esac
case "${SCENARIO}" in
  functional|moderate|high|capacity|slow-payment|intermittent-failures) ;;
  *) echo "[ERROR] Unsupported SCENARIO: ${SCENARIO}" >&2; exit 2 ;;
esac
case "${SCENARIO}" in
  moderate) LOAD_MODEL="constant-arrival-rate"; CONFIGURED_RATE="${RATE:-25}"; CONFIGURED_VUS="" ;;
  high) LOAD_MODEL="constant-arrival-rate"; CONFIGURED_RATE="${RATE:-150}"; CONFIGURED_VUS="" ;;
  capacity) LOAD_MODEL="constant-vus"; CONFIGURED_RATE=""; CONFIGURED_VUS="${VUS:-200}" ;;
  slow-payment|intermittent-failures) LOAD_MODEL="constant-arrival-rate"; CONFIGURED_RATE="${RATE:-10}"; CONFIGURED_VUS="" ;;
  functional) LOAD_MODEL="shared-iterations"; CONFIGURED_RATE=""; CONFIGURED_VUS="1" ;;
esac
command -v k6 >/dev/null 2>&1 || { echo "[ERROR] k6 is required." >&2; exit 1; }
[[ "${HEARTBEAT_SECONDS}" =~ ^[1-9][0-9]*$ ]] || {
  echo "[ERROR] HEARTBEAT_SECONDS must be a positive integer." >&2
  exit 2
}

if [[ "${MEASURED_RUN}" == "true" ]]; then
  git -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "[ERROR] A formal measured run requires an initialized Git repository." >&2
    exit 1
  }
  [[ -z "$(git -C "${ROOT}" status --porcelain)" ]] || {
    echo "[ERROR] A formal measured run requires a clean worktree." >&2
    exit 1
  }
  git -C "${ROOT}" rev-parse --verify HEAD >/dev/null 2>&1 || {
    echo "[ERROR] A formal measured run requires a committed Git HEAD." >&2
    exit 1
  }
fi

RUN_ID="${RUN_ID:-$(date -u +%Y%m%d-%H%M%SZ)-${IMPLEMENTATION}-${SCENARIO}}"
OUT="${OUT:-${ROOT}/.artifacts/${RUN_ID}}"
mkdir -p "${OUT}" "${LAB}/load-tests/results"

git_sha="unknown"
git_branch="not-a-git-repository"
if git -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_sha="$(git -C "${ROOT}" rev-parse HEAD)"
  git_branch="$(git -C "${ROOT}" branch --show-current)"
fi
cat > "${OUT}/load-test.env" <<ENV
RUN_ID=${RUN_ID}
IMPLEMENTATION=${IMPLEMENTATION}
SCENARIO=${SCENARIO}
BASE_URL=${BASE_URL}
GIT_SHA=${git_sha}
GIT_BRANCH=${git_branch}
MEASURED_RUN=${MEASURED_RUN}
PAIR=${PAIR}
WORKLOAD_SEED=${WORKLOAD_SEED}
LOAD_MODEL=${LOAD_MODEL}
CONFIGURED_RATE=${CONFIGURED_RATE}
CONFIGURED_VUS=${CONFIGURED_VUS}
ENV

k6_args=(run)
if [[ "${K6_RAW_OUTPUT}" == "true" ]]; then
  k6_args+=(--out "json=${OUT}/k6-points.json")
fi
k6_args+=("${LAB}/load-tests/checkout.js")

console_file="${OUT}/k6-console.txt"
k6_pid=""
heartbeat_pid=""
heartbeat_stop_file="${OUT}/.heartbeat.stop"
cleanup() {
  local rc=$?
  trap - EXIT INT TERM
  set +e
  if [[ -n "${heartbeat_pid}" ]]; then
    : > "${heartbeat_stop_file}" 2>/dev/null || true
    wait "${heartbeat_pid}" 2>/dev/null || true
  fi
  if [[ -n "${k6_pid}" ]] && kill -0 "${k6_pid}" 2>/dev/null; then
    kill "${k6_pid}" 2>/dev/null
    wait "${k6_pid}" 2>/dev/null
  fi
  exit "${rc}"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "[K6] start implementation=${IMPLEMENTATION} scenario=${SCENARIO} run_id=${RUN_ID}"
started_seconds="${SECONDS}"
started_ns="$(date +%s%N)"
: > "${console_file}"
set +e
SUMMARY_PATH="${OUT}/k6-summary.json" \
BASE_URL="${BASE_URL}" IMPLEMENTATION="${IMPLEMENTATION}" SCENARIO="${SCENARIO}" RUN_ID="${RUN_ID}" \
PAIR="${PAIR}" WORKLOAD_SEED="${WORKLOAD_SEED}" \
  k6 "${k6_args[@]}" > "${console_file}" 2>&1 &
k6_pid=$!
rm -f "${heartbeat_stop_file}"
(
  heartbeat_elapsed=0
  while [[ ! -e "${heartbeat_stop_file}" ]]; do
    sleep 1
    heartbeat_elapsed=$((heartbeat_elapsed + 1))
    if [[ ! -e "${heartbeat_stop_file}" ]] && (( heartbeat_elapsed % HEARTBEAT_SECONDS == 0 )); then
      echo "[K6] still running elapsed=${heartbeat_elapsed}s implementation=${IMPLEMENTATION} scenario=${SCENARIO}"
    fi
  done
) &
heartbeat_pid=$!

wait "${k6_pid}"
k6_rc=$?
ended_ns="$(date +%s%N)"
k6_pid=""
: > "${heartbeat_stop_file}"
wait "${heartbeat_pid}" 2>/dev/null || true
heartbeat_pid=""
rm -f "${heartbeat_stop_file}"
set -e
elapsed_ms=$(((ended_ns - started_ns) / 1000000))
elapsed_seconds=$((SECONDS - started_seconds))
cat "${console_file}"
echo "[K6] finished elapsed=${elapsed_seconds}s elapsed_ms=${elapsed_ms} exit_code=${k6_rc}" | tee -a "${console_file}"
cat >> "${OUT}/load-test.env" <<ENV
K6_STARTED_NS=${started_ns}
K6_ENDED_NS=${ended_ns}
K6_ELAPSED_MS=${elapsed_ms}
K6_EXIT_CODE=${k6_rc}
ENV

if [[ -s "${OUT}/k6-points.json" ]] && command -v gzip >/dev/null 2>&1; then
  gzip -f "${OUT}/k6-points.json"
fi

if (( k6_rc != 0 )); then
  exit "${k6_rc}"
fi
trap - EXIT INT TERM
echo "[OK] Load evidence written to ${OUT}."
