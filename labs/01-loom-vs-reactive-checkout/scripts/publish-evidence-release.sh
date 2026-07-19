#!/usr/bin/env bash
set -euo pipefail

SUITE_DIR="${1:?Usage: publish-evidence-release.sh <suite-directory> <release-tag>}"
TAG="${2:?Usage: publish-evidence-release.sh <suite-directory> <release-tag>}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command -v gh >/dev/null 2>&1 || { echo "[ERROR] GitHub CLI is required." >&2; exit 1; }
gh auth status >/dev/null

"${SCRIPT_DIR}/package-evidence.sh" "${SUITE_DIR}"
SUITE_DIR="$(cd "${SUITE_DIR}" && pwd)"
archive="$(dirname "${SUITE_DIR}")/$(basename "${SUITE_DIR}").tar.gz"

if ! gh release view "${TAG}" >/dev/null 2>&1; then
  gh release create "${TAG}" \
    --title "Java Architecture Decision Lab ${TAG}" \
    --notes "Automated performance evidence. Results are specific to the documented environment and are not a definitive benchmark."
fi

gh release upload "${TAG}" "${archive}" "${archive}.sha256" --clobber
echo "[OK] Evidence assets uploaded to release ${TAG}."
