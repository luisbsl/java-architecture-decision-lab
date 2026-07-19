#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/evidence-common.sh"

IMPLEMENTATION="${IMPLEMENTATION:?Set IMPLEMENTATION}"
OUT="${OUT:?Set OUT}"
PHASE="${PHASE:-snapshot}"
CONTAINER="$(implementation_container "${IMPLEMENTATION}")"
mkdir -p "${OUT}"

capture() {
  local name="$1"
  shift
  if jcmd_container "${CONTAINER}" "$@" > "${OUT}/${PHASE}-${name}.txt" 2>&1; then
    echo "[OK] ${PHASE}-${name}.txt"
  else
    echo "[WARN] Unable to capture ${name}; see artifact." >&2
  fi
}

capture jvm-version VM.version
capture command-line VM.command_line
capture flags VM.flags
capture system-properties VM.system_properties
capture heap-info GC.heap_info
capture class-histogram GC.class_histogram
capture thread-dump Thread.print -l
capture native-memory VM.native_memory summary scale=MB

echo "[OK] Container JVM diagnostics captured for ${IMPLEMENTATION}."
