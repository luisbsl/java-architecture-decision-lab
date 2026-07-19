#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/evidence-common.sh"
STATE_DIR="${REPO_ROOT}/.artifacts/visualvm"
STATE_FILE="${STATE_DIR}/current.env"

usage() {
  cat <<'USAGE'
Usage:
  visualvm-session.sh start <mvc-vthreads|webflux-reactor> [scenario]
  visualvm-session.sh load [scenario]
  visualvm-session.sh status
  visualvm-session.sh stop
USAGE
}

start_session() {
  local implementation="${1:?implementation required}"
  local scenario="${2:-moderate}"
  local service module base_url visualvm_id jar session_id out pid git_sha
  service="$(implementation_service "${implementation}")"
  base_url="$(implementation_base_url "${implementation}")"
  case "${implementation}" in
    mvc-vthreads)
      module="labs/01-loom-vs-reactive-checkout/mvc-virtual-threads"
      visualvm_id="mvc-vthreads"
      ;;
    webflux-reactor)
      module="labs/01-loom-vs-reactive-checkout/webflux-reactor"
      visualvm_id="webflux-reactor"
      ;;
  esac

  [[ ! -f "${STATE_FILE}" ]] || {
    echo "[ERROR] A VisualVM session is already registered. Run stop first." >&2
    exit 1
  }
  require_command docker
  require_command java
  configure_scenario_environment "${scenario}"
  mkdir -p "${STATE_DIR}"
  session_id="$(date -u +%Y%m%dT%H%M%SZ)-${implementation}-${scenario}-visualvm"
  out="${STATE_DIR}/${session_id}"
  mkdir -p "${out}"

  "${REPO_ROOT}/mvnw" --batch-mode --no-transfer-progress \
    -pl "${module}" -am package -DskipTests

  docker compose -f "${BASE_COMPOSE}" down --remove-orphans >/dev/null 2>&1 || true
  docker compose -f "${BASE_COMPOSE}" up --build -d external-services-simulator
  wait_for_http "http://localhost:8083/actuator/health/readiness" 180

  jar="$(find "${REPO_ROOT}/${module}/target" -maxdepth 1 -type f -name '*.jar' ! -name '*-sources.jar' | head -1)"
  [[ -n "${jar}" ]] || { echo "[ERROR] Application jar not found." >&2; exit 1; }

  SIMULATOR_BASE_URL=http://localhost:8083 \
  java -Dvisualvm.id="${visualvm_id}" -XX:NativeMemoryTracking=summary \
    -jar "${jar}" > "${out}/application.log" 2>&1 &
  pid=$!
  echo "${pid}" > "${out}/application.pid"
  cat > "${STATE_FILE}" <<ENV
SESSION_ID=${session_id}
IMPLEMENTATION=${implementation}
SERVICE=${service}
BASE_URL=${base_url}
PID=${pid}
OUT=${out}
VISUALVM_ID=${visualvm_id}
SCENARIO=${scenario}
ENV

  wait_for_http "${base_url}/actuator/health/readiness" 180
  git_sha="$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || echo unknown)"
  cat > "${out}/VISUALVM_CAPTURE_CHECKLIST.md" <<CHECKLIST
# VisualVM Capture Checklist — ${session_id}

Implementation: ${implementation}  
Scenario: ${scenario}  
Git SHA: ${git_sha}  
PID: ${pid}

- [ ] ${session_id}-visualvm-overview-before.png
- [ ] ${session_id}-visualvm-monitor-measured.png
- [ ] ${session_id}-visualvm-cpu-sampler.nps
- [ ] ${session_id}-visualvm-cpu-hot-methods.png
- [ ] ${session_id}-visualvm-memory-sampler.nps
- [ ] ${session_id}-visualvm-memory-allocations.png
- [ ] ${session_id}-visualvm-threads-measured.png
- [ ] ${session_id}-visualvm-thread-dump.tdump when an outlier is investigated
- [ ] ${session_id}-visualvm-application.apps

For every PNG, add a sidecar describing capture phase, elapsed time, observation, and limitation.
CHECKLIST
  IMPLEMENTATION="${implementation}" SCENARIO=visualvm RUN_NUMBER=1 RUN_ID="${session_id}" \
    OUT="${out}" FORMAL_RUN=false "${SCRIPT_DIR}/capture-environment.sh" >/dev/null

  if command -v visualvm >/dev/null 2>&1; then
    visualvm --openpid "${pid}" >/dev/null 2>&1 &
    echo "[OK] VisualVM launched for PID ${pid}."
  else
    echo "[WARN] VisualVM command not found. Open PID ${pid} manually." >&2
  fi
  echo "[OK] Session=${session_id} PID=${pid} OUT=${out}"
  echo "[NEXT] ${0} load ${scenario}"
}

load_session() {
  local requested_scenario="${1:-}"
  [[ -f "${STATE_FILE}" ]] || { echo "[ERROR] No active VisualVM session." >&2; exit 1; }
  # shellcheck disable=SC1090
  source "${STATE_FILE}"
  local scenario="${requested_scenario:-${SCENARIO}}"
  if [[ "${scenario}" != "${SCENARIO}" ]]; then
    echo "[ERROR] Session simulator was started for ${SCENARIO}; restart the session for ${scenario}." >&2
    exit 2
  fi
  kill -0 "${PID}" 2>/dev/null || { echo "[ERROR] Native JVM is not running." >&2; exit 1; }

  echo "[PHASE] 20-second warm-up"
  IMPLEMENTATION="${IMPLEMENTATION}" SCENARIO=moderate BASE_URL="${BASE_URL}" \
    RATE=5 DURATION=20s PRE_ALLOCATED_VUS=10 MAX_VUS=30 \
    RUN_ID="${SESSION_ID}-warmup" OUT="${OUT}/warmup" K6_RAW_OUTPUT=false \
    "${SCRIPT_DIR}/run-load-test.sh"

  echo "[PHASE] measured ${scenario} load"
  IMPLEMENTATION="${IMPLEMENTATION}" SCENARIO="${scenario}" BASE_URL="${BASE_URL}" \
    RUN_ID="${SESSION_ID}-${scenario}" OUT="${OUT}/load-${scenario}" K6_RAW_OUTPUT=true \
    "${SCRIPT_DIR}/run-load-test.sh"
  echo "[OK] VisualVM load window complete. Capture and save the required snapshots now."
}

status_session() {
  [[ -f "${STATE_FILE}" ]] || { echo "[INFO] No active session."; exit 0; }
  cat "${STATE_FILE}"
  # shellcheck disable=SC1090
  source "${STATE_FILE}"
  if kill -0 "${PID}" 2>/dev/null; then
    echo "[OK] Native JVM ${PID} is running."
  else
    echo "[WARN] State exists but PID ${PID} is not running." >&2
  fi
}

stop_session() {
  if [[ -f "${STATE_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${STATE_FILE}"
    kill "${PID}" 2>/dev/null || true
    wait "${PID}" 2>/dev/null || true
    rm -f "${STATE_FILE}"
    echo "[OK] Native JVM stopped."
  fi
  docker compose -f "${BASE_COMPOSE}" down --remove-orphans >/dev/null 2>&1 || true
  echo "[OK] Simulator stopped."
}

case "${1:-}" in
  start) shift; start_session "$@" ;;
  load) shift; load_session "$@" ;;
  status) status_session ;;
  stop) stop_session ;;
  *) usage; exit 2 ;;
esac
