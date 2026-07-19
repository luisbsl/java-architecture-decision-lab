#!/usr/bin/env bash
set -euo pipefail

OUT="${OUT:?Set OUT to an existing evidence directory}"
SAMPLES="${SAMPLES:-0}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-2}"
STOP_FILE="${STOP_FILE:-}"
READY_FILE="${READY_FILE:-}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BASE_COMPOSE="${LAB_DIR}/docker-compose.yml"
EVIDENCE_COMPOSE="${LAB_DIR}/docker-compose.evidence.yml"
STATS_TIMEOUT_SECONDS="${STATS_TIMEOUT_SECONDS:-20}"
OUTPUT_FILE="${OUT}/docker-stats.csv"

command -v docker >/dev/null 2>&1 || {
  echo "[ERROR] Docker is required." >&2
  exit 1
}
command -v timeout >/dev/null 2>&1 || {
  echo "[ERROR] GNU timeout is required." >&2
  exit 1
}
[[ "${SAMPLES}" =~ ^[0-9]+$ ]] || { echo "[ERROR] SAMPLES must be a non-negative integer." >&2; exit 2; }
[[ "${INTERVAL_SECONDS}" =~ ^[1-9][0-9]*$ ]] || { echo "[ERROR] INTERVAL_SECONDS must be positive." >&2; exit 2; }
if [[ "${SAMPLES}" == "0" && -z "${STOP_FILE}" ]]; then
  echo "[ERROR] Set SAMPLES>0 or provide STOP_FILE for lifecycle-controlled capture." >&2
  exit 2
fi

mkdir -p "${OUT}"
printf 'epoch_ns,utc,name,cpu_percent,memory_usage,net_io,block_io,pids\n' > "${OUTPUT_FILE}"
sample=0
stop_requested() {
  [[ -n "${STOP_FILE}" && -e "${STOP_FILE}" ]]
}

sleep_interruptibly() {
  local remaining="${INTERVAL_SECONDS}"
  while (( remaining > 0 )); do
    stop_requested && return 0
    sleep 1
    remaining=$((remaining - 1))
  done
}

while :; do
  stop_requested && break
  if (( SAMPLES > 0 && sample >= SAMPLES )); then
    break
  fi
  sample=$((sample + 1))
  epoch_ns="$(date +%s%N)"
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
  sample_file="$(mktemp "${OUT}/.docker-stats-sample.XXXXXX")"
  if timeout --foreground --signal=TERM --kill-after=5s "${STATS_TIMEOUT_SECONDS}s" \
    docker compose -f "${BASE_COMPOSE}" -f "${EVIDENCE_COMPOSE}" \
      stats --no-stream --no-trunc \
      --format "${epoch_ns},${timestamp},{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}" \
      > "${sample_file}"; then
    cat "${sample_file}" >> "${OUTPUT_FILE}"
  else
    echo "[WARN] Docker stats sample ${sample} timed out or failed." >&2
  fi
  rm -f "${sample_file}"
  if (( sample == 1 )) && [[ -n "${READY_FILE}" ]]; then
    : > "${READY_FILE}"
  fi

  stop_requested && break
  if (( SAMPLES > 0 && sample >= SAMPLES )); then
    break
  fi
  sleep_interruptibly
 done

printf '[OK] Docker stats capture stopped after %d samples: %s\n' "${sample}" "${OUTPUT_FILE}"
