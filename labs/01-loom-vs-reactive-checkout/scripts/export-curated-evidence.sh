#!/usr/bin/env bash
set -euo pipefail

SUITE_DIR="${1:?Usage: export-curated-evidence.sh <suite-directory>}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Backward-compatible alias for the complete materialization pipeline.
# It extracts structured JFR metrics, rebuilds run summaries, aggregates the suite,
# and writes the curated documentation tree. Formal export requires complete runs
# with known Git SHAs.
exec "${SCRIPT_DIR}/materialize-evidence-docs.sh" "${SUITE_DIR}"
