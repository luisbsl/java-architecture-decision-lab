#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if (($# != 1)); then
  echo "Usage: finalize-evidence-suite.sh <suite-dir>" >&2
  exit 2
fi

SUITE_DIR="$(cd -- "$1" && pwd)"
[[ -f "${SUITE_DIR}/suite.env" ]] || {
  echo "[ERROR] Suite directory does not contain suite.env: ${SUITE_DIR}" >&2
  exit 1
}

summary_count="$(find "${SUITE_DIR}" -mindepth 2 -maxdepth 2 -name run-summary.json -type f | wc -l | tr -d ' ')"
scenarios="$(awk -F= '$1=="SCENARIOS" {print $2}' "${SUITE_DIR}/suite.env")"
pairs="$(awk -F= '$1=="PAIRS" {print $2}' "${SUITE_DIR}/suite.env")"
IFS=',' read -r -a scenario_list <<< "${scenarios}"
expected_count=$((${#scenario_list[@]} * pairs * 2))

if [[ "${summary_count}" != "${expected_count}" ]]; then
  echo "[ERROR] Finalization requires a complete suite: found=${summary_count} expected=${expected_count}." >&2
  echo "[INFO] Resume the interrupted execution with the exact original Git revision and protocol configuration." >&2
  exit 1
fi

echo "[PHASE] Aggregating normalized summaries."
python3 "${SCRIPT_DIR}/aggregate-evidence.py" "${SUITE_DIR}"

echo "[PHASE] Auditing immutable run artifacts and protocol gates."
python3 "${SCRIPT_DIR}/audit-evidence-suite.py" "${SUITE_DIR}"

echo "[PHASE] Rebuilding suite integrity manifest."
(
  cd "${SUITE_DIR}"
  find . -type f ! -name suite-manifest.sha256 -print0 \
    | sort -z \
    | xargs -0 sha256sum > suite-manifest.sha256
)

echo "[OK] Evidence suite finalized without rerunning measured workloads: ${SUITE_DIR}"
echo "[OK] Runs=${summary_count}/${expected_count}; audit=${SUITE_DIR}/SUITE_AUDIT.md"
