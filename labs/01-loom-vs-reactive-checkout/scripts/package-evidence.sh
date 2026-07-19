#!/usr/bin/env bash
set -euo pipefail

SUITE_DIR="${1:?Usage: package-evidence.sh <suite-directory>}"
SUITE_DIR="$(cd "${SUITE_DIR}" && pwd)"
[[ -f "${SUITE_DIR}/COMPARISON.md" ]] || {
  echo "[ERROR] Not a completed evidence suite: ${SUITE_DIR}" >&2
  exit 1
}
name="$(basename "${SUITE_DIR}")"
out="$(dirname "${SUITE_DIR}")/${name}.tar.gz"

tar -C "$(dirname "${SUITE_DIR}")" -czf "${out}" "${name}"
(
  cd "$(dirname "${out}")"
  sha256sum "$(basename "${out}")" > "$(basename "${out}").sha256"
)
echo "[OK] ${out}"
echo "[OK] ${out}.sha256"
