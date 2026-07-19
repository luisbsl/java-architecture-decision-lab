#!/usr/bin/env bash
set -euo pipefail

PID="${PID:?Set PID to the target JVM process}"
OUT="${OUT:?Set OUT to an existing evidence directory}"
PHASE="${PHASE:-snapshot}"

command -v jcmd >/dev/null 2>&1 || {
  echo "[ERROR] jcmd is required and must run under a compatible user context." >&2
  exit 1
}

mkdir -p "${OUT}"
jcmd "${PID}" VM.version      > "${OUT}/${PHASE}-jvm-version.txt"
jcmd "${PID}" VM.command_line > "${OUT}/${PHASE}-jvm-command-line.txt"
jcmd "${PID}" VM.flags        > "${OUT}/${PHASE}-jvm-flags.txt"
jcmd "${PID}" GC.heap_info    > "${OUT}/${PHASE}-heap-info.txt"
jcmd "${PID}" Thread.print    > "${OUT}/${PHASE}-thread-dump.txt"

echo "[OK] JVM diagnostics '${PHASE}' captured for PID ${PID}."
