#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from collections import defaultdict
from pathlib import Path
from typing import Any

AUDIT_POLICY_VERSION = "2"
CONTROLLED_WORKLOAD_BOUNDARY_TOLERANCE = 1


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fail closed when an evidence suite violates publication-grade integrity guardrails."
    )
    parser.add_argument("suite_dir", type=Path)
    return parser.parse_args()


def read_env(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    if not path.exists():
        return result
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


def finite(value: Any) -> float | None:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) else None


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for block in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def validate_manifest(run: Path) -> list[str]:
    manifest = run / "manifest.sha256"
    if not manifest.exists():
        return ["manifest_missing"]
    issues: list[str] = []
    for line in manifest.read_text(encoding="utf-8").splitlines():
        if "  " not in line:
            issues.append("manifest_malformed")
            continue
        expected, relative = line.split("  ", 1)
        artifact = run / relative.removeprefix("./")
        if not artifact.exists():
            issues.append(f"manifest_artifact_missing:{relative}")
        elif sha256(artifact) != expected:
            issues.append(f"manifest_hash_mismatch:{relative}")
    return issues


def stats_bounds(path: Path) -> tuple[int | None, int | None]:
    if not path.exists():
        return None, None
    values: list[int] = []
    with path.open(newline="", encoding="utf-8") as file:
        for row in csv.DictReader(file):
            try:
                values.append(int(row.get("epoch_ns", "")))
            except (TypeError, ValueError):
                pass
    return (min(values), max(values)) if values else (None, None)


def controlled_workload_pair_issues(
    mvc: dict[str, Any], webflux: dict[str, Any], scenario: str, pair: int
) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    if "arrival-rate" not in str(mvc.get("load_model")):
        return errors, warnings

    mvc_iterations = finite(mvc.get("iterations"))
    webflux_iterations = finite(webflux.get("iterations"))
    measured_seconds = finite(mvc.get("_measured_seconds"))
    webflux_measured_seconds = finite(webflux.get("_measured_seconds"))
    configured_rate = finite(mvc.get("configured_rate_rps"))

    if mvc_iterations is None or webflux_iterations is None:
        return [f"controlled_workload_iterations_missing:{scenario}:{pair}"], warnings
    if measured_seconds is None or webflux_measured_seconds is None:
        return [f"controlled_workload_duration_missing:{scenario}:{pair}"], warnings
    if measured_seconds != webflux_measured_seconds:
        return [f"controlled_workload_duration_mismatch:{scenario}:{pair}"], warnings
    if configured_rate is None:
        return [f"controlled_workload_rate_missing:{scenario}:{pair}"], warnings

    expected_iterations = configured_rate * measured_seconds
    mvc_boundary_delta = abs(mvc_iterations - expected_iterations)
    webflux_boundary_delta = abs(webflux_iterations - expected_iterations)
    pair_delta = abs(mvc_iterations - webflux_iterations)

    if (
        mvc_boundary_delta > CONTROLLED_WORKLOAD_BOUNDARY_TOLERANCE
        or webflux_boundary_delta > CONTROLLED_WORKLOAD_BOUNDARY_TOLERANCE
    ):
        errors.append(f"controlled_workload_expected_iteration_mismatch:{scenario}:{pair}")
    elif pair_delta > CONTROLLED_WORKLOAD_BOUNDARY_TOLERANCE:
        errors.append(
            f"controlled_workload_pair_iteration_delta_exceeds_tolerance:{scenario}:{pair}"
        )
    elif pair_delta > 0:
        warnings.append(
            f"controlled_workload_boundary_iteration_delta:{scenario}:{pair}:delta={int(pair_delta)}"
        )
    return errors, warnings


def main() -> int:
    suite = parse_args().suite_dir.resolve()
    suite_env = read_env(suite / "suite.env")
    try:
        protocol_version = int(suite_env.get("PROTOCOL_VERSION", "0"))
    except ValueError:
        protocol_version = 0

    run_reports: list[dict[str, Any]] = []
    pair_records: dict[tuple[str, int], dict[str, dict[str, Any]]] = defaultdict(dict)
    global_errors: list[str] = []
    global_warnings: list[str] = []

    summaries = sorted(suite.rglob("run-summary.json"))
    if not summaries:
        raise SystemExit("[ERROR] No run-summary.json files found")

    for summary_path in summaries:
        run = summary_path.parent
        summary = json.loads(summary_path.read_text(encoding="utf-8"))
        env = read_env(run / "run.env")
        errors = validate_manifest(run)
        warnings: list[str] = []

        if protocol_version >= 4:
            if finite(summary.get("dropped_iterations")) not in (0.0,):
                errors.append("dropped_iterations_non_zero_or_missing")
            if (finite(summary.get("docker_stats_sample_count")) or 0) <= 0:
                errors.append("application_stats_missing_in_measured_window")
            if (finite(summary.get("simulator_stats_sample_count")) or 0) <= 0:
                errors.append("simulator_stats_missing_in_measured_window")
            if finite(summary.get("jfr_data_loss_event_count")) not in (0.0,):
                errors.append("jfr_data_loss_non_zero_or_missing")

            start_ns = int(env["measured_start_ns"]) if env.get("measured_start_ns", "").isdigit() else None
            end_ns = int(env["measured_end_ns"]) if env.get("measured_end_ns", "").isdigit() else None
            stats_min, stats_max = stats_bounds(run / "docker-stats.csv")
            if start_ns is None or end_ns is None:
                errors.append("measured_window_missing")
            elif end_ns <= start_ns:
                errors.append("measured_window_invalid")
            if stats_min is None or stats_max is None:
                errors.append("timestamped_stats_missing")
            elif start_ns is not None and end_ns is not None:
                if stats_min >= start_ns:
                    errors.append("pre_load_stats_baseline_missing")
                if stats_max > end_ns + 5_000_000_000:
                    errors.append("stats_continue_more_than_5s_after_k6")

            overhead = finite(summary.get("jfr_window_overhead_seconds"))
            if overhead is None or abs(overhead) > 5.0:
                errors.append("jfr_window_not_bounded_to_k6")
            measured = finite(summary.get("measured_window_seconds"))
            k6_ms = finite(summary.get("k6_test_duration_ms"))
            if measured is not None and k6_ms is not None and abs(measured - k6_ms / 1000) > 2.0:
                errors.append("k6_and_measured_window_differ_by_more_than_2s")

            if summary.get("git_sha") != suite_env.get("GIT_SHA"):
                errors.append("git_sha_mismatch")
            if str(summary.get("workload_seed")) != suite_env.get("WORKLOAD_SEED"):
                errors.append("workload_seed_mismatch")
            if env.get("PROTOCOL_FINGERPRINT") != suite_env.get("PROTOCOL_FINGERPRINT"):
                errors.append("protocol_fingerprint_mismatch")

        summary["_measured_seconds"] = finite(env.get("MEASURED_SECONDS"))
        pair_records[(summary["scenario"], int(summary["pair"]))][summary["implementation"]] = summary
        run_reports.append(
            {
                "run_id": summary["run_id"],
                "errors": sorted(set(errors)),
                "warnings": sorted(set(warnings)),
            }
        )

    if protocol_version >= 4:
        try:
            pairs = int(suite_env.get("PAIRS", "0"))
        except ValueError:
            pairs = 0
        if pairs % 2 != 0:
            global_errors.append("pair_count_is_not_even")

        for (scenario, pair), implementations in sorted(pair_records.items()):
            mvc = implementations.get("mvc-vthreads")
            webflux = implementations.get("webflux-reactor")
            if not mvc or not webflux:
                global_errors.append(f"incomplete_pair:{scenario}:{pair}")
                continue
            if mvc.get("load_model") != webflux.get("load_model"):
                global_errors.append(f"load_model_mismatch:{scenario}:{pair}")
            if mvc.get("configured_rate_rps") != webflux.get("configured_rate_rps"):
                global_errors.append(f"configured_rate_mismatch:{scenario}:{pair}")
            if mvc.get("workload_seed") != webflux.get("workload_seed"):
                global_errors.append(f"workload_seed_pair_mismatch:{scenario}:{pair}")
            pair_errors, pair_warnings = controlled_workload_pair_issues(
                mvc, webflux, scenario, pair
            )
            global_errors.extend(pair_errors)
            global_warnings.extend(pair_warnings)

    failed_runs = [report for report in run_reports if report["errors"]]
    document = {
        "schema_version": "1.1",
        "audit_policy_version": AUDIT_POLICY_VERSION,
        "controlled_workload_boundary_tolerance": CONTROLLED_WORKLOAD_BOUNDARY_TOLERANCE,
        "audit_script_sha256": sha256(Path(__file__).resolve()),
        "suite_id": suite.name,
        "protocol_version": protocol_version,
        "status": "pass" if not failed_runs and not global_errors else "fail",
        "run_count": len(run_reports),
        "failed_run_count": len(failed_runs),
        "global_errors": sorted(set(global_errors)),
        "global_warnings": sorted(set(global_warnings)),
        "runs": run_reports,
    }
    (suite / "suite-audit.json").write_text(
        json.dumps(document, indent=2, allow_nan=False) + "\n", encoding="utf-8"
    )

    lines = [
        "# Evidence Suite Audit",
        "",
        f"- Status: **{document['status'].upper()}**",
        f"- Protocol version: `{protocol_version}`",
        f"- Audit policy version: `{AUDIT_POLICY_VERSION}`",
        f"- Controlled-workload boundary tolerance: `±{CONTROLLED_WORKLOAD_BOUNDARY_TOLERANCE} iteration`",
        f"- Audit script SHA-256: `{document['audit_script_sha256']}`",
        f"- Runs audited: **{len(run_reports)}**",
        f"- Failed runs: **{len(failed_runs)}**",
        "",
    ]
    if global_errors:
        lines.extend(["## Global errors", ""] + [f"- `{issue}`" for issue in sorted(set(global_errors))] + [""])
    if global_warnings:
        lines.extend(["## Global warnings", ""] + [f"- `{issue}`" for issue in sorted(set(global_warnings))] + [""])
    if failed_runs:
        lines.extend(["## Run errors", ""])
        for report in failed_runs:
            lines.append(f"- `{report['run_id']}`: {', '.join(report['errors'])}")
        lines.append("")
    if not global_errors and not failed_runs:
        lines.extend(
            [
                "All per-run manifests, measured-window bounds, stats lifecycle, dropped-iteration gates, JFR bounds, Git/protocol identity, and paired controlled-workload gates passed.",
                "A one-iteration scheduler-boundary delta is accepted only when both runs remain within ±1 iteration of the configured rate × measured duration; any larger deviation fails closed.",
                "",
            ]
        )
    (suite / "SUITE_AUDIT.md").write_text("\n".join(lines), encoding="utf-8")

    if document["status"] != "pass":
        print(f"[ERROR] Evidence suite audit failed: {suite}")
        return 1
    print(f"[OK] Evidence suite audit passed: {suite}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
