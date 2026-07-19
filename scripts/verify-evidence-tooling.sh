#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LAB="${ROOT}/labs/01-loom-vs-reactive-checkout"

"${ROOT}/scripts/verify-repository-consistency.py"

find "${LAB}/scripts" -maxdepth 1 -type f -name '*.sh' -print0 \
  | xargs -0 -r bash -n

# Parse every Python source file without creating __pycache__ or .pyc files.
# This gate must be idempotent because verify-all.sh invokes it again.
PYTHONDONTWRITEBYTECODE=1 python3 -B - "${LAB}/scripts" <<'PY'
from __future__ import annotations

import ast
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
failures: list[str] = []

for path in sorted(root.rglob("*.py")):
    try:
        source = path.read_text(encoding="utf-8")
        ast.parse(source, filename=str(path))
    except (OSError, SyntaxError, UnicodeError) as exc:
        failures.append(f"{path}: {exc}")

if failures:
    for failure in failures:
        print(f"[ERROR] python_syntax:{failure}", file=sys.stderr)
    raise SystemExit(1)

print(f"[OK] Python syntax validation passed files={len(list(root.rglob('*.py')))}.")
PY

PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -v \
  -s "${LAB}/scripts/tests" -p 'test_*.py'

# Regression gate: repository-relative paths passed through `make -C` must resolve
# against the repository root, not the lab directory.
relative_suite_probe=".artifacts/evidence/path-resolution-probe"
expected_suite_probe="${ROOT}/${relative_suite_probe}"
make_path_probe="$(
  make -s -C "${LAB}" --dry-run evidence-audit \
    SUITE_DIR="${relative_suite_probe}"
)"
if ! grep -F -- "${expected_suite_probe}" <<<"${make_path_probe}" >/dev/null; then
  echo "[ERROR] make_c_path_resolution:${make_path_probe}" >&2
  exit 1
fi
echo "[OK] Make -C repository-relative path resolution passed."

java_build_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_jfc:-}" "${java_build_dir}"' EXIT
javac -d "${java_build_dir}" "${LAB}/scripts/ExtractJfrMetrics.java"

tmp_jfc="$(mktemp --suffix=.jfc)"
jfr configure \
  --input "${ROOT}/docs/profiling/evidence-profile.jfc" \
  --output "${tmp_jfc}" >/dev/null
[[ -s "${tmp_jfc}" ]]

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker compose \
    -f "${LAB}/docker-compose.yml" \
    -f "${LAB}/docker-compose.evidence.yml" \
    config --quiet
else
  echo "[WARN] Docker unavailable; Compose evidence override was not rendered." >&2
fi

# Regression gate: evidence archive checksums must remain valid after relocation.
package_probe_root="$(mktemp -d)"
mkdir -p "${package_probe_root}/suite"
printf '# probe\n' > "${package_probe_root}/suite/COMPARISON.md"
"${LAB}/scripts/package-evidence.sh" "${package_probe_root}/suite" >/dev/null
mkdir -p "${package_probe_root}/moved"
mv "${package_probe_root}/suite.tar.gz" "${package_probe_root}/suite.tar.gz.sha256" "${package_probe_root}/moved/"
(
  cd "${package_probe_root}/moved"
  sha256sum -c suite.tar.gz.sha256 >/dev/null
)
rm -rf "${package_probe_root}"
echo "[OK] Portable evidence-package checksum passed."

# Re-run the repository gate to prove this verifier did not create forbidden source-tree artifacts.
"${ROOT}/scripts/verify-repository-consistency.py"

echo "[OK] Evidence tooling verification passed."
