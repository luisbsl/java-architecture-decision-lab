#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"
SCENARIOS="moderate"
PAIRS=4
OUT_ROOT="${REPO_ROOT}/.artifacts/evidence"
RESUME_DIR=""
RUN_TIMEOUT_SECONDS=""
PREBUILD=true
COOLDOWN_SECONDS="${COOLDOWN_SECONDS:-10}"
WORKLOAD_SEED="${WORKLOAD_SEED:-20260718}"

usage() {
  cat <<'USAGE'
Usage: run-evidence-suite.sh [options]

Options:
  --scenarios <csv>          Scenarios to execute (default: moderate)
  --pairs <n>                Paired repetitions per scenario (default: 4; must be even)
  --output-root <path>       Evidence root directory
  --resume <suite-dir>       Resume an interrupted suite, skipping completed runs
  --run-timeout-seconds <n>  Override the watchdog for every individual run
  --cooldown-seconds <n>     Cooldown between isolated runs (default: 10)
  --workload-seed <value>    Deterministic synthetic workload seed
  --no-prebuild              Do not build images once before the suite
  -h, --help                 Show this help
USAGE
}

while (($#)); do
  case "$1" in
    --scenarios) SCENARIOS="${2:?}"; shift 2 ;;
    --pairs) PAIRS="${2:?}"; shift 2 ;;
    --output-root) OUT_ROOT="${2:?}"; shift 2 ;;
    --resume) RESUME_DIR="${2:?}"; shift 2 ;;
    --run-timeout-seconds) RUN_TIMEOUT_SECONDS="${2:?}"; shift 2 ;;
    --cooldown-seconds) COOLDOWN_SECONDS="${2:?}"; shift 2 ;;
    --workload-seed) WORKLOAD_SEED="${2:?}"; shift 2 ;;
    --no-prebuild) PREBUILD=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERROR] Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ "${PAIRS}" =~ ^[1-9][0-9]*$ ]] || {
  echo "[ERROR] --pairs must be a positive integer." >&2
  exit 2
}
(( PAIRS % 2 == 0 )) || {
  echo "[ERROR] Formal paired evidence requires an even --pairs value to balance execution order." >&2
  exit 2
}
[[ "${COOLDOWN_SECONDS}" =~ ^[0-9]+$ ]] || {
  echo "[ERROR] --cooldown-seconds must be a non-negative integer." >&2
  exit 2
}
if [[ -n "${RUN_TIMEOUT_SECONDS}" && ! "${RUN_TIMEOUT_SECONDS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "[ERROR] --run-timeout-seconds must be a positive integer." >&2
  exit 2
fi
command -v docker >/dev/null 2>&1 || { echo "[ERROR] Docker is required." >&2; exit 1; }
command -v timeout >/dev/null 2>&1 || {
  echo "[ERROR] GNU timeout is required for the suite watchdog." >&2
  exit 1
}
command -v sha256sum >/dev/null 2>&1 || {
  echo "[ERROR] sha256sum is required for protocol identity." >&2
  exit 1
}

git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "[ERROR] Formal paired evidence requires an initialized Git repository." >&2
  exit 1
}
[[ -z "$(git -C "${REPO_ROOT}" status --porcelain)" ]] || {
  echo "[ERROR] Formal paired evidence requires a clean worktree." >&2
  exit 1
}
CURRENT_GIT_SHA="$(git -C "${REPO_ROOT}" rev-parse --verify HEAD)"
CURRENT_GIT_BRANCH="$(git -C "${REPO_ROOT}" branch --show-current)"

# Normalize defaults that affect the measured system so every child run receives
# the exact same values and resume cannot silently mix incompatible executions.
BENCHMARK_LOG_LEVEL="${BENCHMARK_LOG_LEVEL:-WARN}"
APP_CPUS="${APP_CPUS:-2.0}"
APP_MEMORY="${APP_MEMORY:-1g}"
SIMULATOR_CPUS="${SIMULATOR_CPUS:-2.0}"
SIMULATOR_MEMORY="${SIMULATOR_MEMORY:-1g}"
WARMUP_SECONDS="${WARMUP_SECONDS:-20}"
export BENCHMARK_LOG_LEVEL APP_CPUS APP_MEMORY SIMULATOR_CPUS SIMULATOR_MEMORY WARMUP_SECONDS

setting_value() {
  local name="$1"
  if [[ -v "${name}" ]]; then
    printf '%s' "${!name}"
  else
    printf '%s' '__DEFAULT__'
  fi
}

suite_configuration() {
  local keys=(
    BENCHMARK_LOG_LEVEL APP_CPUS APP_MEMORY SIMULATOR_CPUS SIMULATOR_MEMORY
    WARMUP_SECONDS WARMUP_RATE DURATION_SECONDS RATE VUS PRE_ALLOCATED_VUS MAX_VUS
    REQUEST_TIMEOUT P95_THRESHOLD_MS P99_THRESHOLD_MS GRACEFUL_STOP
    PAYMENT_MIN_DELAY_OVERRIDE PAYMENT_MAX_DELAY_OVERRIDE
    DOWNSTREAM_READ_TIMEOUT_OVERRIDE PAYMENT_FAILURE_RATE_OVERRIDE
  )
  local key
  for key in "${keys[@]}"; do
    printf '%s=%s\n' "${key}" "$(setting_value "${key}")"
  done
}

protocol_fingerprint() {
  (
    export LC_ALL=C
    cd "${REPO_ROOT}"
    {
      find labs/01-loom-vs-reactive-checkout \
        -type f \
        \( -name '*.java' -o -name '*.xml' -o -name '*.yml' -o -name '*.yaml' \
           -o -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name 'Dockerfile' \) \
        ! -path '*/target/*' ! -path '*/load-tests/results/*' -print0
      printf '%s\0' docs/profiling/evidence-profile.jfc
    } | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
  )
}

PROTOCOL_VERSION=5
PROTOCOL_FINGERPRINT="$(protocol_fingerprint)"
SUITE_CONFIG_FINGERPRINT="$(suite_configuration | sha256sum | awk '{print $1}')"
export PROTOCOL_FINGERPRINT SUITE_CONFIG_FINGERPRINT

IFS=',' read -r -a scenario_list <<< "${SCENARIOS}"
for scenario in "${scenario_list[@]}"; do
  case "${scenario}" in
    functional|moderate|high|capacity|slow-payment|intermittent-failures) ;;
    *) echo "[ERROR] Unsupported scenario: ${scenario}" >&2; exit 2 ;;
  esac
done

if [[ -n "${RESUME_DIR}" ]]; then
  SUITE_DIR="$(cd -- "${RESUME_DIR}" && pwd)"
  [[ -f "${SUITE_DIR}/suite.env" ]] || {
    echo "[ERROR] Resume directory does not contain suite.env: ${SUITE_DIR}" >&2
    exit 1
  }
  recorded_scenarios="$(awk -F= '$1=="SCENARIOS" {print $2}' "${SUITE_DIR}/suite.env")"
  recorded_pairs="$(awk -F= '$1=="PAIRS" {print $2}' "${SUITE_DIR}/suite.env")"
  recorded_version="$(awk -F= '$1=="PROTOCOL_VERSION" {print $2}' "${SUITE_DIR}/suite.env")"
  recorded_fingerprint="$(awk -F= '$1=="PROTOCOL_FINGERPRINT" {print $2}' "${SUITE_DIR}/suite.env")"
  recorded_git_sha="$(awk -F= '$1=="GIT_SHA" {print $2}' "${SUITE_DIR}/suite.env")"
  recorded_config_fingerprint="$(awk -F= '$1=="SUITE_CONFIG_FINGERPRINT" {print $2}' "${SUITE_DIR}/suite.env")"
  [[ "${recorded_scenarios}" == "${SCENARIOS}" && "${recorded_pairs}" == "${PAIRS}" ]] || {
    echo "[ERROR] Resume parameters do not match suite.env." >&2
    echo "[INFO] recorded scenarios=${recorded_scenarios} pairs=${recorded_pairs}" >&2
    echo "[INFO] requested scenarios=${SCENARIOS} pairs=${PAIRS}" >&2
    exit 1
  }
  [[ "${recorded_version}" == "${PROTOCOL_VERSION}"       && "${recorded_fingerprint}" == "${PROTOCOL_FINGERPRINT}" ]] || {
    echo "[ERROR] The suite was created by a different evidence protocol revision." >&2
    echo "[INFO] recorded version=${recorded_version:-missing} fingerprint=${recorded_fingerprint:-missing}" >&2
    echo "[INFO] current  version=${PROTOCOL_VERSION} fingerprint=${PROTOCOL_FINGERPRINT}" >&2
    echo "[INFO] Start a new formal suite; keep the old directory only for diagnosis." >&2
    exit 1
  }
  [[ "${recorded_git_sha}" == "${CURRENT_GIT_SHA}" ]] || {
    echo "[ERROR] The current Git SHA differs from the suite Git SHA." >&2
    echo "[INFO] recorded=${recorded_git_sha:-missing} current=${CURRENT_GIT_SHA}" >&2
    exit 1
  }
  [[ "${recorded_config_fingerprint}" == "${SUITE_CONFIG_FINGERPRINT}" ]] || {
    echo "[ERROR] Runtime/resource configuration differs from the original suite." >&2
    echo "[INFO] recorded=${recorded_config_fingerprint:-missing}" >&2
    echo "[INFO] current=${SUITE_CONFIG_FINGERPRINT}" >&2
    echo "[INFO] Start a new suite rather than mixing incompatible runs." >&2
    exit 1
  }
  SUITE_ID="$(basename "${SUITE_DIR}")"
  echo "[INFO] Resuming suite: ${SUITE_DIR}"
else
  SUITE_ID="$(date -u +%Y%m%dT%H%M%SZ)-paired-evidence"
  SUITE_DIR="$(mkdir -p "${OUT_ROOT}" && cd "${OUT_ROOT}" && pwd)/${SUITE_ID}"
  mkdir -p "${SUITE_DIR}"
  cat > "${SUITE_DIR}/suite.env" <<ENV
SUITE_ID=${SUITE_ID}
SCENARIOS=${SCENARIOS}
PAIRS=${PAIRS}
PAIR_ORDER=odd:mvc-webflux;even:webflux-mvc
COOLDOWN_SECONDS=${COOLDOWN_SECONDS}
WORKLOAD_SEED=${WORKLOAD_SEED}
PROTOCOL_VERSION=${PROTOCOL_VERSION}
PROTOCOL_FINGERPRINT=${PROTOCOL_FINGERPRINT}
SUITE_CONFIG_FINGERPRINT=${SUITE_CONFIG_FINGERPRINT}
GIT_SHA=${CURRENT_GIT_SHA}
GIT_BRANCH=${CURRENT_GIT_BRANCH}
ENV
  suite_configuration > "${SUITE_DIR}/suite-configuration.env"
fi

FAILURE_PHASE="execution"
suite_interrupted() {
  local rc=$?
  trap - EXIT INT TERM
  if (( rc != 0 )); then
    echo "[ERROR] Evidence suite stopped with exit code ${rc}." >&2
    if [[ "${FAILURE_PHASE}" == "finalization" ]]; then
      echo "[INFO] All measured runs completed. Do not resume or rerun them." >&2
      echo "[INFO] After correcting the post-processing/audit issue, finalize the existing suite:" >&2
      echo "  ${SCRIPT_DIR}/finalize-evidence-suite.sh '${SUITE_DIR}'" >&2
    else
      echo "[INFO] Resume without repeating completed runs:" >&2
      echo "  ${SCRIPT_DIR}/run-evidence-suite.sh --scenarios ${SCENARIOS} --pairs ${PAIRS} --resume '${SUITE_DIR}'" >&2
    fi
  fi
  exit "${rc}"
}
trap suite_interrupted EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

completed_run_exists() {
  local scenario="$1" pair="$2" order="$3" implementation="$4"
  local summary env_file
  while IFS= read -r -d '' summary; do
    env_file="$(dirname "${summary}")/run.env"
    [[ -f "${env_file}" ]] || continue
    if grep -qx "SCENARIO=${scenario}" "${env_file}" \
      && grep -qx "PAIR=${pair}" "${env_file}" \
      && grep -qx "ORDER=${order}" "${env_file}" \
      && grep -qx "IMPLEMENTATION=${implementation}" "${env_file}"; then
      return 0
    fi
  done < <(find "${SUITE_DIR}" -mindepth 2 -maxdepth 2 -name run-summary.json -print0)
  return 1
}

scenario_timeout_seconds() {
  case "$1" in
    functional) echo 180 ;;
    moderate|slow-payment|intermittent-failures) echo 300 ;;
    high|capacity) echo 420 ;;
  esac
}

scenario_estimate_seconds() {
  case "$1" in
    functional) echo 45 ;;
    moderate|slow-payment|intermittent-failures) echo 100 ;;
    high|capacity) echo 165 ;;
  esac
}

scenario_count="${#scenario_list[@]}"
total_runs=$((scenario_count * PAIRS * 2))
estimated_seconds=0
for scenario in "${scenario_list[@]}"; do
  estimated_seconds=$((estimated_seconds + $(scenario_estimate_seconds "${scenario}") * PAIRS * 2))
done
printf '[PLAN] suite=%s scenarios=%s pairs=%d total_runs=%d estimated_minutes≈%d\n' \
  "${SUITE_ID}" "${SCENARIOS}" "${PAIRS}" "${total_runs}" "$(((estimated_seconds + 59) / 60))"
echo "[PLAN] protocol_version=${PROTOCOL_VERSION} fingerprint=${PROTOCOL_FINGERPRINT} config_fingerprint=${SUITE_CONFIG_FINGERPRINT} git_sha=${CURRENT_GIT_SHA}"
echo "[PLAN] Each pair contains two isolated runs: MVC + Virtual Threads and WebFlux/Reactor."
echo "[PLAN] Completed runs are detected by run-summary.json and skipped when resuming."

if [[ "${PREBUILD}" == "true" ]]; then
  echo "[PHASE] Pre-building the three Docker images once for the whole suite."
  timeout --foreground --signal=TERM --kill-after=30s "${PREBUILD_TIMEOUT_SECONDS:-900}s" \
    docker compose \
    -f "${SCRIPT_DIR}/../docker-compose.yml" \
    -f "${SCRIPT_DIR}/../docker-compose.evidence.yml" \
    build external-services-simulator mvc-virtual-threads webflux-reactor
fi

run_index=0
completed=0
skipped=0
for scenario in "${scenario_list[@]}"; do
  for ((pair=1; pair<=PAIRS; pair++)); do
    if (( pair % 2 == 1 )); then
      implementations=(mvc-vthreads webflux-reactor)
    else
      implementations=(webflux-reactor mvc-vthreads)
    fi
    order=1
    for implementation in "${implementations[@]}"; do
      run_index=$((run_index + 1))
      if completed_run_exists "${scenario}" "${pair}" "${order}" "${implementation}"; then
        skipped=$((skipped + 1))
        printf '[SUITE %02d/%02d] SKIP completed scenario=%s pair=%d order=%d implementation=%s\n' \
          "${run_index}" "${total_runs}" "${scenario}" "${pair}" "${order}" "${implementation}"
        order=$((order + 1))
        continue
      fi

      timeout_seconds="${RUN_TIMEOUT_SECONDS:-$(scenario_timeout_seconds "${scenario}")}"
      printf '[SUITE %02d/%02d] START scenario=%s pair=%d/%d order=%d implementation=%s watchdog=%ss\n' \
        "${run_index}" "${total_runs}" "${scenario}" "${pair}" "${PAIRS}" "${order}" "${implementation}" "${timeout_seconds}"
      started="${SECONDS}"
      set +e
      timeout --foreground --signal=TERM --kill-after=30s "${timeout_seconds}s" \
        env WORKLOAD_SEED="${WORKLOAD_SEED}" \
        "${SCRIPT_DIR}/run-evidence.sh" \
          --implementation "${implementation}" \
          --scenario "${scenario}" \
          --run-number "${pair}" \
          --pair "${pair}" \
          --order "${order}" \
          --output-root "${SUITE_DIR}" \
          --skip-build
      run_rc=$?
      set -e
      elapsed=$((SECONDS - started))
      if (( run_rc == 124 || run_rc == 137 )); then
        echo "[ERROR] Run exceeded the ${timeout_seconds}s watchdog." >&2
        exit 124
      elif (( run_rc != 0 )); then
        echo "[ERROR] Run failed with exit code ${run_rc}." >&2
        exit "${run_rc}"
      fi
      completed=$((completed + 1))
      printf '[SUITE %02d/%02d] DONE elapsed=%ss completed_now=%d skipped=%d\n' \
        "${run_index}" "${total_runs}" "${elapsed}" "${completed}" "${skipped}"
      if (( COOLDOWN_SECONDS > 0 && run_index < total_runs )); then
        printf '[PHASE] cooldown=%ss before next isolated run\n' "${COOLDOWN_SECONDS}"
        sleep "${COOLDOWN_SECONDS}"
      fi
      order=$((order + 1))
    done
  done
done

FAILURE_PHASE="finalization"
"${SCRIPT_DIR}/finalize-evidence-suite.sh" "${SUITE_DIR}"

trap - EXIT INT TERM
echo "[OK] Paired evidence suite completed: ${SUITE_DIR}"
echo "[OK] New runs=${completed}; previously completed/skipped=${skipped}; expected total=${total_runs}."
