#!/usr/bin/env bash
set -euo pipefail

PID="${PID:?Set PID to the target JVM process}"
OUT="${OUT:?Set OUT to an existing evidence directory}"
RUN_ID="${RUN_ID:-jfr-$(date -u +%Y%m%d-%H%M%SZ)}"
DURATION="${DURATION:-120s}"
SETTINGS="${SETTINGS:-profile}"

command -v jcmd >/dev/null 2>&1 || {
  echo "[ERROR] jcmd is required." >&2
  exit 1
}

mkdir -p "${OUT}"
JFR_FILE="$(cd "${OUT}" && pwd)/${RUN_ID}.jfr"

jcmd "${PID}" JFR.start \
  name="${RUN_ID}" \
  settings="${SETTINGS}" \
  duration="${DURATION}" \
  filename="${JFR_FILE}" \
  dumponexit=true

jcmd "${PID}" JFR.check | tee "${OUT}/${RUN_ID}-jfr-check.txt"

echo "[OK] Bounded JFR recording started: ${JFR_FILE}"
echo "[INFO] Inspect after ${DURATION} with JDK Mission Control."
