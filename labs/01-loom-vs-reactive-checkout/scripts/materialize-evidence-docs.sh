#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: materialize-evidence-docs.sh [suite-directory] [options]

When suite-directory is omitted, the newest .artifacts/evidence/*-paired-evidence
folder containing suite.env is selected automatically.

Options:
  --latest                Explicitly select the newest local evidence suite.
  --update-analysis       Refresh the managed evidence block in the comparative analysis.
  --refresh-jfr           Rejected for formal suites: raw evidence is immutable.
  --allow-partial         Generate a diagnostic preview from an incomplete suite.
  --allow-unknown-git     Allow diagnostic evidence whose run Git SHA is unknown.
USAGE
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"
SUITE_DIR=""
LATEST=false
if [[ $# -gt 0 && "$1" != --* ]]; then
  SUITE_DIR="$1"
  shift
fi

UPDATE_ANALYSIS=false
REFRESH_JFR=false
ALLOW_PARTIAL=false
ALLOW_UNKNOWN_GIT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --latest) LATEST=true ;;
    --update-analysis) UPDATE_ANALYSIS=true ;;
    --refresh-jfr) REFRESH_JFR=true ;;
    --allow-partial) ALLOW_PARTIAL=true ;;
    --allow-unknown-git) ALLOW_UNKNOWN_GIT=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERROR] Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ -z "${SUITE_DIR}" || "${LATEST}" == true ]]; then
  EVIDENCE_ROOT="${EVIDENCE_ROOT:-${REPO_ROOT}/.artifacts/evidence}"
  SUITE_DIR="$(
    find "${EVIDENCE_ROOT}" -mindepth 1 -maxdepth 1 -type d -name '*-paired-evidence' \
      -exec test -f '{}/suite.env' ';' -print 2>/dev/null | sort | tail -n 1
  )"
  [[ -n "${SUITE_DIR}" ]] || {
    echo "[ERROR] No evidence suite with suite.env found under ${EVIDENCE_ROOT}" >&2
    exit 1
  }
  echo "[INFO] Selected latest evidence suite: ${SUITE_DIR}"
fi

SUITE_DIR="$(cd -- "${SUITE_DIR}" && pwd)"
[[ -f "${SUITE_DIR}/suite.env" ]] || {
  echo "[ERROR] suite.env not found: ${SUITE_DIR}" >&2
  exit 1
}

if [[ "${REFRESH_JFR}" == true ]]; then
  echo "[ERROR] Formal raw suites are immutable. Copy the suite to a diagnostic workspace before refreshing JFR reports." >&2
  exit 2
fi

"${SCRIPT_DIR}/audit-evidence-suite.py" "${SUITE_DIR}"

processed=0
while IFS= read -r -d '' run_dir; do
  [[ -f "${run_dir}/load/k6-summary.json" ]] || continue
  [[ -s "${run_dir}/recording.jfr" ]] || {
    echo "[ERROR] Completed k6 run has no recording.jfr: ${run_dir}" >&2
    exit 1
  }
  report_dir="${run_dir}/jfr-reports"
  [[ -s "${report_dir}/jfr-metrics.json" && -s "${report_dir}/JFR_METRICS.md" ]] || {
    echo "[ERROR] Immutable formal run is missing structured JFR reports: ${run_dir}" >&2
    exit 1
  }
  [[ -s "${run_dir}/run-summary.json" && -s "${run_dir}/RUN_SUMMARY.md" ]] || {
    echo "[ERROR] Immutable formal run is missing normalized summaries: ${run_dir}" >&2
    exit 1
  }
  processed=$((processed + 1))
done < <(find "${SUITE_DIR}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

(( processed > 0 )) || {
  echo "[ERROR] No completed runs found in ${SUITE_DIR}" >&2
  exit 1
}

[[ -s "${SUITE_DIR}/comparison-aggregates.json" && -s "${SUITE_DIR}/COMPARISON.md" ]] || {
  echo "[ERROR] Immutable suite is missing aggregate outputs." >&2
  exit 1
}

args=("${SUITE_DIR}")
[[ "${UPDATE_ANALYSIS}" == true ]] && args+=(--update-analysis)
[[ "${ALLOW_PARTIAL}" == true ]] && args+=(--allow-partial)
[[ "${ALLOW_UNKNOWN_GIT}" == true ]] && args+=(--allow-unknown-git)
python3 "${SCRIPT_DIR}/generate-evidence-docs.py" "${args[@]}"

CURATED_DIR="${REPO_ROOT}/docs/results/evidence/$(basename "${SUITE_DIR}")"
python3 "${SCRIPT_DIR}/generate-mermaid-charts.py" "${CURATED_DIR}"
(
  cd "${CURATED_DIR}"
  find . -type f ! -name curated-manifest.sha256 -printf '%P\0' \
    | LC_ALL=C sort -z \
    | xargs -0 sha256sum > curated-manifest.sha256
)
"${SCRIPT_DIR}/validate-curated-evidence.sh" "${CURATED_DIR}"

echo "[OK] Evidence extraction, documentation materialization, and integrity validation completed."
echo "[INFO] CURATED_DIR=${CURATED_DIR}"
echo "[INFO] Revalidate later with: make -C labs/01-loom-vs-reactive-checkout evidence-validate"
