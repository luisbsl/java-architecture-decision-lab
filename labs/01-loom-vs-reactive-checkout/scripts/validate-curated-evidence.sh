#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: validate-curated-evidence.sh [curated-directory]

When curated-directory is omitted, validates the newest
`docs/results/evidence/*-paired-evidence` directory containing
`curated-manifest.sha256`.
USAGE
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"
CURATED_DIR="${1:-}"

if [[ "${CURATED_DIR}" == "-h" || "${CURATED_DIR}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "${CURATED_DIR}" ]]; then
  CURATED_ROOT="${CURATED_ROOT:-${REPO_ROOT}/docs/results/evidence}"
  CURATED_DIR="$(
    find "${CURATED_ROOT}" \
      -mindepth 1 \
      -maxdepth 1 \
      -type d \
      -name '*-paired-evidence' \
      -exec test -f '{}/curated-manifest.sha256' ';' \
      -printf '%T@ %p\n' 2>/dev/null \
    | sort -n \
    | tail -n 1 \
    | cut -d' ' -f2-
  )"
fi

[[ -n "${CURATED_DIR}" ]] || {
  echo "[ERROR] No curated evidence directory with curated-manifest.sha256 was found." >&2
  exit 1
}

CURATED_DIR="$(cd -- "${CURATED_DIR}" && pwd)"
MANIFEST="${CURATED_DIR}/curated-manifest.sha256"

[[ -s "${MANIFEST}" ]] || {
  echo "[ERROR] Missing or empty manifest: ${MANIFEST}" >&2
  exit 1
}

required=(
  README.md
  COMPARISON.md
  FACTUAL_OBSERVATIONS.md
  comparison.csv
  comparison-aggregates.json
  suite.env
)
for relative in "${required[@]}"; do
  [[ -s "${CURATED_DIR}/${relative}" ]] || {
    echo "[ERROR] Required curated artifact is missing or empty: ${CURATED_DIR}/${relative}" >&2
    exit 1
  }
done

printf '[INFO] curated_dir=%s\n' "${CURATED_DIR}"
(
  cd -- "${CURATED_DIR}"
  sha256sum -c curated-manifest.sha256
)
printf '[OK] Curated evidence integrity validated.\n'
