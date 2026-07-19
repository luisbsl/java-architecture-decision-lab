#!/usr/bin/env bash
set -euo pipefail

JFR_FILE="${1:?Usage: render-jfr-reports.sh <recording.jfr> [output-directory]}"
OUT="${2:-$(dirname -- "${JFR_FILE}")/jfr-reports}"
REPORT_TIMEOUT_SECONDS="${REPORT_TIMEOUT_SECONDS:-60}"
command -v jfr >/dev/null 2>&1 || {
  echo "[ERROR] JDK 21 jfr command is required." >&2
  exit 1
}
command -v timeout >/dev/null 2>&1 || {
  echo "[ERROR] GNU timeout is required." >&2
  exit 1
}
[[ -s "${JFR_FILE}" ]] || {
  echo "[ERROR] JFR file is missing or empty: ${JFR_FILE}" >&2
  exit 1
}
mkdir -p "${OUT}"
rm -f "${OUT}/concurrency-events.json" "${OUT}/concurrency-events.json.gz"

timeout --foreground --signal=TERM --kill-after=5s "${REPORT_TIMEOUT_SECONDS}s" \
  jfr summary "${JFR_FILE}" > "${OUT}/summary.txt"
for view in \
  recording cpu-load hot-methods allocation-by-class allocation-by-site \
  gc gc-pauses thread-count thread-cpu-load pinned-threads \
  socket-reads-by-host socket-writes-by-host container-cpu-usage \
  container-memory-usage events-by-count; do
  timeout --foreground --signal=TERM --kill-after=5s "${REPORT_TIMEOUT_SECONDS}s" \
    jfr view --width 180 --cell-height 12 "${view}" "${JFR_FILE}" \
    > "${OUT}/${view}.txt" 2>&1 || {
      echo "[WARN] JFR view '${view}' failed or timed out." >&2
    }
done

# Full ThreadPark/JavaMonitorEnter JSON expands a small binary JFR into hundreds of
# megabytes of repeated stack data. Counts and predefined views remain the formal
# comparison artifacts; raw JSON is restricted to rare virtual-thread failures.
grep -E 'jdk\.(VirtualThreadPinned|VirtualThreadSubmitFailed|JavaMonitorEnter|ThreadPark)' \
  "${OUT}/summary.txt" > "${OUT}/concurrency-event-counts.txt" || true

timeout --foreground --signal=TERM --kill-after=5s "${REPORT_TIMEOUT_SECONDS}s" \
  jfr print --json --stack-depth 32 \
  --events 'jdk.VirtualThreadPinned,jdk.VirtualThreadSubmitFailed' \
  "${JFR_FILE}" > "${OUT}/virtual-thread-events.json" 2>/dev/null || {
    echo "[WARN] Virtual-thread event export failed or timed out." >&2
    rm -f "${OUT}/virtual-thread-events.json"
  }

if [[ -s "${OUT}/virtual-thread-events.json" ]] && command -v gzip >/dev/null 2>&1; then
  gzip -f "${OUT}/virtual-thread-events.json"
fi

command -v java >/dev/null 2>&1 || {
  echo "[ERROR] Java 21 is required for structured JFR extraction." >&2
  exit 1
}
java "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/ExtractJfrMetrics.java" \
  "${JFR_FILE}" "${OUT}"

echo "[OK] Bounded JFR reports and structured metrics generated in ${OUT}."
