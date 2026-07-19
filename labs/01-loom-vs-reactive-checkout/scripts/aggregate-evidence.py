#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path
from typing import Any

PERFORMANCE_METRICS = (
    "rps",
    "schedule_adherence_percent",
    "dropped_iterations",
    "avg_ms",
    "p95_ms",
    "p99_ms",
    "error_percent",
    "cpu_avg_percent",
    "cpu_p95_percent",
    "memory_baseline_mib",
    "memory_avg_mib",
    "memory_peak_mib",
    "memory_peak_delta_mib",
    "simulator_cpu_avg_percent",
    "simulator_memory_peak_mib",
)
JFR_METRICS = (
    "jfr_process_cpu_avg_percent",
    "jfr_cpu_one_core_percent",
    "jfr_cpu_equivalent_cores",
    "jfr_allocation_pressure_mib_s",
    "jfr_gc_count",
    "jfr_gc_pause_total_ms",
    "jfr_gc_pause_max_ms",
    "jfr_gc_pause_ratio_percent",
    "jfr_platform_threads_avg",
    "jfr_platform_threads_max",
    "jfr_active_threads_avg",
    "jfr_active_threads_max",
    "jfr_thread_park_count",
    "jfr_monitor_enter_count",
    "jfr_virtual_thread_pinned_count",
    "jfr_data_loss_event_count",
)
PAIR_METRICS = (
    "rps",
    "avg_ms",
    "p95_ms",
    "p99_ms",
    "cpu_avg_percent",
    "memory_peak_delta_mib",
    "jfr_cpu_one_core_percent",
    "jfr_allocation_pressure_mib_s",
    "jfr_gc_pause_ratio_percent",
    "jfr_platform_threads_max",
)
CSV_FIELDS = (
    "run_id",
    "implementation",
    "stack",
    "scenario",
    "pair",
    "order",
    "run_number",
    "git_sha",
    "workload_seed",
    "load_model",
    "throughput_semantics",
    "configured_rate_rps",
    "configured_vus",
    *PERFORMANCE_METRICS,
    "confirmed_rate_percent",
    "iterations",
    "k6_test_duration_ms",
    "measured_window_seconds",
    "docker_stats_sample_count",
    "simulator_stats_sample_count",
    "host_logical_cpus",
    "jfr_recording_seconds",
    "jfr_window_overhead_seconds",
    "jfr_process_cpu_p95_percent",
    *JFR_METRICS,
    "jfr_thread_park_total_ms",
    "jfr_virtual_thread_submit_failed_count",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("suite_dir", type=Path)
    return parser.parse_args()


def finite(value: Any) -> float | None:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) else None


def summary(values: list[Any]) -> dict[str, float | int | None]:
    clean = [number for value in values if (number := finite(value)) is not None]
    if not clean:
        return {"count": 0, "median": None, "mean": None, "min": None, "max": None, "cv_percent": None}
    mean = statistics.fmean(clean)
    cv = statistics.pstdev(clean) / abs(mean) * 100 if len(clean) > 1 and mean != 0 else 0.0
    return {
        "count": len(clean),
        "median": statistics.median(clean),
        "mean": mean,
        "min": min(clean),
        "max": max(clean),
        "cv_percent": cv,
    }


def fmt(stat: dict[str, float | int | None], decimals: int = 3) -> str:
    if not stat["count"]:
        return "n/a"
    return (
        f"{float(stat['median']):.{decimals}f} "
        f"[{float(stat['min']):.{decimals}f}, {float(stat['max']):.{decimals}f}] "
        f"CV={float(stat['cv_percent']):.1f}%"
    )


def read_env(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    if not path.exists():
        return result
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


def expected_slots(suite_env: dict[str, str]) -> dict[tuple[str, int, int], str] | None:
    try:
        scenarios = [scenario for scenario in suite_env["SCENARIOS"].split(",") if scenario]
        pairs = int(suite_env["PAIRS"])
    except (KeyError, ValueError):
        return None
    slots: dict[tuple[str, int, int], str] = {}
    for scenario in scenarios:
        for pair in range(1, pairs + 1):
            implementations = (
                ("mvc-vthreads", "webflux-reactor")
                if pair % 2 == 1
                else ("webflux-reactor", "mvc-vthreads")
            )
            for order, implementation in enumerate(implementations, start=1):
                slots[(scenario, pair, order)] = implementation
    return slots


def paired_comparisons(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_pair: dict[tuple[str, int], dict[str, dict[str, Any]]] = defaultdict(dict)
    for record in records:
        by_pair[(record["scenario"], int(record["pair"]))][record["implementation"]] = record

    deltas: dict[tuple[str, str], list[float]] = defaultdict(list)
    percent_deltas: dict[tuple[str, str], list[float]] = defaultdict(list)
    completed_pairs: dict[str, set[int]] = defaultdict(set)
    for (scenario, pair), implementations in by_pair.items():
        mvc = implementations.get("mvc-vthreads")
        webflux = implementations.get("webflux-reactor")
        if not mvc or not webflux:
            continue
        completed_pairs[scenario].add(pair)
        for metric_name in PAIR_METRICS:
            mvc_value = finite(mvc.get(metric_name))
            webflux_value = finite(webflux.get(metric_name))
            if mvc_value is None or webflux_value is None:
                continue
            delta = webflux_value - mvc_value
            deltas[(scenario, metric_name)].append(delta)
            if mvc_value != 0:
                percent_deltas[(scenario, metric_name)].append(delta / mvc_value * 100)

    result: list[dict[str, Any]] = []
    for scenario in sorted(completed_pairs):
        metrics: dict[str, Any] = {}
        for metric_name in PAIR_METRICS:
            metrics[metric_name] = {
                "webflux_minus_mvc": summary(deltas[(scenario, metric_name)]),
                "webflux_minus_mvc_percent": summary(percent_deltas[(scenario, metric_name)]),
            }
        result.append(
            {
                "scenario": scenario,
                "completed_pairs": len(completed_pairs[scenario]),
                "metrics": metrics,
            }
        )
    return result


def run_validation_issues(record: dict[str, Any], protocol_version: int) -> list[str]:
    if protocol_version < 4:
        return []
    issues: list[str] = []
    if finite(record.get("dropped_iterations")) not in (None, 0.0):
        issues.append("dropped_iterations_non_zero")
    if (finite(record.get("docker_stats_sample_count")) or 0) <= 0:
        issues.append("no_measured_window_docker_stats")
    if (finite(record.get("simulator_stats_sample_count")) or 0) <= 0:
        issues.append("no_measured_window_simulator_stats")
    overhead = finite(record.get("jfr_window_overhead_seconds"))
    if overhead is not None and abs(overhead) > 5.0:
        issues.append("jfr_window_differs_from_k6_by_more_than_5s")
    if finite(record.get("jfr_data_loss_event_count")) not in (None, 0.0):
        issues.append("jfr_data_loss")
    return issues


def main() -> int:
    arguments = parse_args()
    suite = arguments.suite_dir.resolve()
    records = [
        json.loads(path.read_text(encoding="utf-8"))
        for path in sorted(suite.rglob("run-summary.json"))
    ]
    if not records:
        raise SystemExit("[ERROR] No run-summary.json files found")

    records.sort(key=lambda row: (row["scenario"], int(row["pair"]), int(row["order"])))
    csv_path = suite / "comparison.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=CSV_FIELDS, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(records)

    groups: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for record in records:
        groups[(record["implementation"], record["scenario"])].append(record)

    aggregates: list[dict[str, Any]] = []
    for (implementation, scenario), rows in sorted(groups.items()):
        aggregate: dict[str, Any] = {
            "implementation": implementation,
            "stack": rows[0].get("stack", implementation),
            "scenario": scenario,
            "load_model": rows[0].get("load_model", "unknown"),
            "throughput_semantics": rows[0].get("throughput_semantics", "unknown"),
            "runs": len(rows),
        }
        for metric_name in (*PERFORMANCE_METRICS, *JFR_METRICS):
            aggregate[metric_name] = summary([row.get(metric_name) for row in rows])
        aggregates.append(aggregate)

    suite_env = read_env(suite / "suite.env")
    try:
        protocol_version = int(suite_env.get("PROTOCOL_VERSION", "0"))
    except ValueError:
        protocol_version = 0
    slots = expected_slots(suite_env)
    expected = len(slots) if slots is not None else None
    actual_slots: dict[tuple[str, int, int], list[str]] = defaultdict(list)
    for record in records:
        actual_slots[(record["scenario"], int(record["pair"]), int(record["order"]))].append(
            record["implementation"]
        )
    missing_runs: list[str] = []
    unexpected_runs: list[str] = []
    implementation_mismatches: list[str] = []
    duplicate_slots: list[str] = []
    if slots is not None:
        for slot, expected_implementation in slots.items():
            observed = actual_slots.get(slot, [])
            label = f"scenario={slot[0]},pair={slot[1]},order={slot[2]}"
            if not observed:
                missing_runs.append(f"{label},implementation={expected_implementation}")
            elif len(observed) > 1:
                duplicate_slots.append(f"{label},observed={observed}")
            elif observed[0] != expected_implementation:
                implementation_mismatches.append(
                    f"{label},expected={expected_implementation},observed={observed[0]}"
                )
        for slot, observed in actual_slots.items():
            if slot not in slots:
                unexpected_runs.append(
                    f"scenario={slot[0]},pair={slot[1]},order={slot[2]},observed={observed}"
                )

    run_validation = {
        record["run_id"]: run_validation_issues(record, protocol_version)
        for record in records
    }
    invalid_runs = {run_id: issues for run_id, issues in run_validation.items() if issues}
    complete = (
        slots is not None
        and not missing_runs
        and not unexpected_runs
        and not implementation_mismatches
        and not duplicate_slots
        and not invalid_runs
        and len(records) == expected
    )
    pairs = paired_comparisons(records)
    aggregate_document = {
        "schema_version": "2.0",
        "suite_id": suite.name,
        "status": "complete" if complete else "partial",
        "completed_runs": len(records),
        "expected_runs": expected,
        "missing_runs": missing_runs,
        "unexpected_runs": unexpected_runs,
        "implementation_mismatches": implementation_mismatches,
        "duplicate_slots": duplicate_slots,
        "invalid_runs": invalid_runs,
        "suite": suite_env,
        "groups": aggregates,
        "paired_comparisons": pairs,
    }
    aggregate_json = suite / "comparison-aggregates.json"
    aggregate_json.write_text(
        json.dumps(aggregate_document, indent=2, allow_nan=False) + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Evidence Comparison",
        "",
        "> **This is not a definitive benchmark.** Values are median `[min, max]` plus coefficient of variation across isolated runs.",
        "",
        f"- Suite: `{suite.name}`",
        f"- Status: **{'complete' if complete else 'partial'}**",
        f"- Completed runs: **{len(records)}**" + (f" / **{expected}**" if expected else ""),
        f"- Protocol version: `{suite_env.get('PROTOCOL_VERSION', 'unknown')}`",
        f"- Protocol fingerprint: `{suite_env.get('PROTOCOL_FINGERPRINT', 'unknown')}`",
        f"- Git SHA: `{suite_env.get('GIT_SHA', 'unknown')}`",
        f"- Workload seed: `{suite_env.get('WORKLOAD_SEED', 'unknown')}`",
        "- Arrival-rate scenarios measure schedule adherence at a controlled rate; only the capacity scenario is interpreted as saturation throughput.",
        "- The compared units are full stacks: MVC/Tomcat/JDK HttpClient versus WebFlux/Reactor Netty/WebClient.",
        "",
        "## HTTP and measured-window container evidence",
        "",
        "| Stack | Scenario | Runs | Achieved req/s | Schedule adherence % | Dropped | Avg ms | p95 ms | p99 ms | App CPU avg % | Memory peak delta MiB | Simulator CPU avg % |",
        "|---|---|---:|---|---|---|---|---|---|---|---|---|",
    ]
    for group in aggregates:
        lines.append(
            f"| {group['stack']} | {group['scenario']} | {group['runs']} | "
            f"{fmt(group['rps'])} | {fmt(group['schedule_adherence_percent'])} | "
            f"{fmt(group['dropped_iterations'], 0)} | {fmt(group['avg_ms'])} | "
            f"{fmt(group['p95_ms'])} | {fmt(group['p99_ms'])} | "
            f"{fmt(group['cpu_avg_percent'])} | {fmt(group['memory_peak_delta_mib'])} | "
            f"{fmt(group['simulator_cpu_avg_percent'])} |"
        )

    lines.extend(
        [
            "",
            "## Structured JFR evidence",
            "",
            "| Stack | Scenario | CPU one-core % | Equivalent cores | Allocation MiB/s | GC pause ratio % | Platform threads avg / max | VThread pinned | JFR data loss |",
            "|---|---|---|---|---|---|---|---:|---:|",
        ]
    )
    for group in aggregates:
        platform_threads = f"{fmt(group['jfr_platform_threads_avg'])} / {fmt(group['jfr_platform_threads_max'])}"
        lines.append(
            f"| {group['stack']} | {group['scenario']} | "
            f"{fmt(group['jfr_cpu_one_core_percent'])} | "
            f"{fmt(group['jfr_cpu_equivalent_cores'])} | "
            f"{fmt(group['jfr_allocation_pressure_mib_s'])} | "
            f"{fmt(group['jfr_gc_pause_ratio_percent'])} | {platform_threads} | "
            f"{fmt(group['jfr_virtual_thread_pinned_count'], 0)} | "
            f"{fmt(group['jfr_data_loss_event_count'], 0)} |"
        )

    lines.extend(["", "## Paired deltas", "", "`WebFlux − MVC`; negative resource/latency deltas favor WebFlux, while positive throughput deltas favor WebFlux.", ""])
    for comparison in pairs:
        lines.extend(
            [
                f"### {comparison['scenario']} — {comparison['completed_pairs']} complete pairs",
                "",
                "| Metric | Absolute paired delta | Paired delta % |",
                "|---|---:|---:|",
            ]
        )
        for metric_name in PAIR_METRICS:
            metric_data = comparison["metrics"][metric_name]
            lines.append(
                f"| `{metric_name}` | {fmt(metric_data['webflux_minus_mvc'])} | "
                f"{fmt(metric_data['webflux_minus_mvc_percent'])} |"
            )
        lines.append("")

    if invalid_runs:
        lines.extend(["## Invalid-run gates", ""])
        for run_id, issues in invalid_runs.items():
            lines.append(f"- `{run_id}`: {', '.join(issues)}")
        lines.append("")

    lines.extend(
        [
            "## Interpretation guardrails",
            "",
            "- Docker metrics are computed only from samples timestamped inside the exact k6 process window.",
            "- The stats collector is lifecycle-controlled and joined before summary and manifest creation.",
            "- `dropped_iterations > 0` invalidates a controlled arrival-rate run.",
            "- Deterministic workload identity and simulator seed make both implementations receive the same synthetic delay sequence within each pair.",
            "- Per-request success logs are disabled in quantitative runs; observability-rich logging belongs in a separate diagnostic scenario.",
            "- Allocation pressure is based on `ObjectAllocationSample.weight`; it is an estimate, not retained heap.",
            "- JFR CPU is sampling-based. `CPU one-core %` converts host-capacity percentage to Docker's one-core-is-100% convention.",
            "- Four or more balanced pairs support descriptive paired analysis; they do not turn a local lab into a universal production benchmark.",
        ]
    )
    (suite / "COMPARISON.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"[OK] {csv_path}")
    print(f"[OK] {aggregate_json}")
    print(f"[OK] {suite / 'COMPARISON.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
