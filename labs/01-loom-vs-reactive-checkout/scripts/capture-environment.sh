#!/usr/bin/env bash
set -euo pipefail

IMPLEMENTATION="${IMPLEMENTATION:?Set IMPLEMENTATION}"
SCENARIO="${SCENARIO:?Set SCENARIO}"
RUN_NUMBER="${RUN_NUMBER:-1}"
FORMAL_RUN="${FORMAL_RUN:-true}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
RUN_ID="${RUN_ID:-$(date -u +%Y%m%d-%H%M%SZ)-${IMPLEMENTATION}-${SCENARIO}-run${RUN_NUMBER}}"
OUT="${OUT:-${ROOT}/.artifacts/${RUN_ID}}"

if git -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ "${FORMAL_RUN}" == "true" ]] && [[ -n "$(git -C "${ROOT}" status --porcelain)" ]]; then
    echo "[ERROR] Formal evidence capture requires a clean worktree." >&2
    exit 1
  fi
  branch="$(git -C "${ROOT}" branch --show-current)"
  commit="$(git -C "${ROOT}" rev-parse HEAD)"
  dirty="$(test -n "$(git -C "${ROOT}" status --porcelain)" && echo true || echo false)"
else
  branch="not-a-git-repository"
  commit="unknown"
  dirty="unknown"
fi

mkdir -p "${OUT}"
{
  echo "run_id=${RUN_ID}"
  echo "utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "implementation=${IMPLEMENTATION}"
  echo "scenario=${SCENARIO}"
  echo "run_number=${RUN_NUMBER}"
  echo "branch=${branch}"
  echo "commit=${commit}"
  echo "dirty=${dirty}"
} | tee "${OUT}/git.txt"

{
  uname -a
  [[ -r /etc/os-release ]] && cat /etc/os-release
  echo
  java -version 2>&1
  echo
  "${ROOT}/mvnw" -version 2>&1 || true
  echo
  command -v jcmd >/dev/null 2>&1 && jcmd -l || true
  command -v jfr >/dev/null 2>&1 && jfr version || true
  echo
  docker --version 2>&1 || true
  docker compose version 2>&1 || true
  command -v k6 >/dev/null 2>&1 && k6 version || true
  command -v visualvm >/dev/null 2>&1 && visualvm --help 2>&1 | head -5 || true
  echo
  lscpu 2>&1 || true
  echo
  free -h 2>&1 || true
  echo
  command -v cpupower >/dev/null 2>&1 && cpupower frequency-info 2>&1 || true
  echo
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
} | tee "${OUT}/environment.txt"

if command -v docker >/dev/null 2>&1; then
  docker compose \
    -f "${ROOT}/labs/01-loom-vs-reactive-checkout/docker-compose.yml" \
    -f "${ROOT}/labs/01-loom-vs-reactive-checkout/docker-compose.evidence.yml" \
    config > "${OUT}/docker-compose-effective.yml" 2>&1 || true
  docker compose \
    -f "${ROOT}/labs/01-loom-vs-reactive-checkout/docker-compose.yml" \
    -f "${ROOT}/labs/01-loom-vs-reactive-checkout/docker-compose.evidence.yml" \
    ps > "${OUT}/docker-compose-ps.txt" 2>&1 || true
  docker info > "${OUT}/docker-info.txt" 2>&1 || true
fi

echo "[OK] Environment captured: ${OUT}"
