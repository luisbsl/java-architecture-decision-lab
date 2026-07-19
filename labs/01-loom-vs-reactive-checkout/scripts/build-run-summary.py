#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import math
import os
import re
import statistics
from pathlib import Path
from typing import Any, NamedTuple

UNITS_TO_MIB = {
    "B": 1 / (1024 * 1024),
    "kB": 1000 / (1024 * 1024),
    "KB": 1000 / (1024 * 1024),
    "KiB": 1 / 1024,
    "MB": 1_000_000 / (1024 * 1024),
    "MiB": 1,
    "GB": 1_000_000_000 / (1024 * 1024),
    "GiB": 1024,
}


class ContainerMetrics(NamedTuple):
    sample_count: int
    baseline_memory_mib: float | None
    cpu_avg_percent: float | None
    cpu_p95_percent: float | None
    memory_avg_mib: float | None
    memory_peak_mib: float | None
    memory_peak_delta_mib: float | None


def args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
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


def metric(data: dict[str, Any], name: str, key: str) -> float | None:
    try:
        return finite(data["metrics"][name]["values"][key])
    except (KeyError, TypeError):
        return None


def parse_memory(value: str) -> float | None:
    first = value.split("/", 1)[0].strip()
    match = re.match(r"([0-9.]+)\s*([A-Za-z]+)", first)
    if not match:
        return None
    number, unit = match.groups()
    factor = UNITS_TO_MIB.get(unit)
    return None if factor is None else float(number) * factor


def percentile(values: list[float], p: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    rank = (len(ordered) - 1) * p
    low = math.floor(rank)
    high = math.ceil(rank)
    if low == high:
        return ordered[low]
    return ordered[low] + (ordered[high] - ordered[low]) * (rank - low)


def docker_metrics(
    path: Path,
    target_fragment: str,
    measured_start_ns: int | None = None,
    measured_end_ns: int | None = None,
) -> ContainerMetrics:
    measured_cpu: list[float] = []
    measured_memory: list[float] = []
    baseline_candidates: list[tuple[int, float]] = []
    legacy_memory: list[float] = []
    legacy_cpu: list[float] = []
    if not path.exists():
        return ContainerMetrics(0, None, None, None, None, None, None)

    with path.open(newline="", encoding="utf-8") as file:
        for row in csv.DictReader(file):
            if target_fragment not in row.get("name", ""):
                continue
            cpu = finite(row.get("cpu_percent", "").rstrip("%"))
            memory = parse_memory(row.get("memory_usage", ""))
            epoch_ns = None
            try:
                epoch_ns = int(row.get("epoch_ns", ""))
            except (TypeError, ValueError):
                pass

            if epoch_ns is None or measured_start_ns is None or measured_end_ns is None:
                if cpu is not None:
                    legacy_cpu.append(cpu)
                if memory is not None:
                    legacy_memory.append(memory)
                continue

            if epoch_ns < measured_start_ns:
                if memory is not None:
                    baseline_candidates.append((epoch_ns, memory))
                continue
            if epoch_ns > measured_end_ns:
                continue
            if cpu is not None:
                measured_cpu.append(cpu)
            if memory is not None:
                measured_memory.append(memory)

    if not measured_cpu and legacy_cpu:
        measured_cpu = legacy_cpu
    if not measured_memory and legacy_memory:
        measured_memory = legacy_memory
    baseline = max(baseline_candidates, default=(0, None), key=lambda item: item[0])[1]
    if baseline is None and measured_memory:
        baseline = measured_memory[0]
    peak = max(measured_memory) if measured_memory else None
    return ContainerMetrics(
        sample_count=max(len(measured_cpu), len(measured_memory)),
        baseline_memory_mib=baseline,
        cpu_avg_percent=statistics.fmean(measured_cpu) if measured_cpu else None,
        cpu_p95_percent=percentile(measured_cpu, 0.95),
        memory_avg_mib=statistics.fmean(measured_memory) if measured_memory else None,
        memory_peak_mib=peak,
        memory_peak_delta_mib=(peak - baseline) if peak is not None and baseline is not None else None,
    )


def fmt(value: float | int | None) -> str:
    if value is None:
        return "n/a"
    if isinstance(value, int):
        return str(value)
    return f"{value:.3f}"


def jfr_value(data: dict[str, Any], key: str) -> float | int | None:
    value = data.get(key)
    if isinstance(value, (int, float)) and math.isfinite(float(value)):
        return value
    return None


def main() -> int:
    run_dir = args().run_dir.resolve()
    env = read_env(run_dir / "run.env")
    load_env = read_env(run_dir / "load" / "load-test.env")

    summary_path = run_dir / "load" / "k6-summary.json"
    data = json.loads(summary_path.read_text(encoding="utf-8"))
    jfr_path = run_dir / "jfr-reports" / "jfr-metrics.json"
    jfr = json.loads(jfr_path.read_text(encoding="utf-8")) if jfr_path.exists() else {}

    implementation = env["IMPLEMENTATION"]
    app_target = "mvc-virtual-threads" if implementation == "mvc-vthreads" else "webflux-reactor"
    measured_start_ns = int(env["measured_start_ns"]) if env.get("measured_start_ns", "").isdigit() else None
    measured_end_ns = int(env["measured_end_ns"]) if env.get("measured_end_ns", "").isdigit() else None
    measured_seconds = (
        (measured_end_ns - measured_start_ns) / 1_000_000_000
        if measured_start_ns is not None and measured_end_ns is not None
        else None
    )
    app = docker_metrics(
        run_dir / "docker-stats.csv", app_target, measured_start_ns, measured_end_ns
    )
    simulator = docker_metrics(
        run_dir / "docker-stats.csv",
        "external-services-simulator",
        measured_start_ns,
        measured_end_ns,
    )
    if measured_start_ns is not None and app.sample_count == 0:
        raise SystemExit("[ERROR] No application Docker stats samples fall inside the measured k6 window")

    rps = metric(data, "http_reqs", "rate")
    configured_rate = finite(load_env.get("CONFIGURED_RATE"))
    dropped_iterations = metric(data, "dropped_iterations", "count") or 0.0
    iterations = metric(data, "iterations", "count")
    test_duration_ms = finite(data.get("state", {}).get("testRunDurationMs"))
    load_model = load_env.get("LOAD_MODEL", "unknown")
    semantics = (
        "capacity-throughput"
        if load_model == "constant-vus"
        else "achieved-arrival-rate"
        if "arrival-rate" in load_model
        else "functional"
    )
    schedule_adherence = (
        rps / configured_rate * 100
        if rps is not None and configured_rate is not None and configured_rate > 0
        else None
    )

    host_logical_cpus = os.cpu_count() or 1
    jfr_cpu_host = finite(jfr_value(jfr, "process_cpu_average_percent"))
    jfr_one_core_percent = jfr_cpu_host * host_logical_cpus if jfr_cpu_host is not None else None
    jfr_equivalent_cores = jfr_one_core_percent / 100 if jfr_one_core_percent is not None else None
    jfr_recording_seconds = finite(jfr_value(jfr, "recording_duration_seconds"))
    gc_pause_total_ms = finite(jfr_value(jfr, "gc_pause_total_ms"))
    gc_pause_ratio = (
        gc_pause_total_ms / (jfr_recording_seconds * 1000) * 100
        if gc_pause_total_ms is not None and jfr_recording_seconds not in (None, 0)
        else None
    )

    result: dict[str, Any] = {
        "run_id": env["RUN_ID"],
        "implementation": implementation,
        "stack": (
            "Spring MVC + Tomcat + Virtual Threads + JDK HttpClient"
            if implementation == "mvc-vthreads"
            else "Spring WebFlux + Reactor Netty + WebClient"
        ),
        "scenario": env["SCENARIO"],
        "pair": int(env["PAIR"]),
        "order": int(env["ORDER"]),
        "run_number": int(env["RUN_NUMBER"]),
        "git_sha": env.get("GIT_SHA", "unknown"),
        "workload_seed": env.get("WORKLOAD_SEED", load_env.get("WORKLOAD_SEED", "unknown")),
        "load_model": load_model,
        "throughput_semantics": semantics,
        "configured_rate_rps": configured_rate,
        "configured_vus": finite(load_env.get("CONFIGURED_VUS")),
        "rps": rps,
        "schedule_adherence_percent": schedule_adherence,
        "iterations": iterations,
        "dropped_iterations": dropped_iterations,
        "k6_test_duration_ms": test_duration_ms,
        "measured_window_seconds": measured_seconds,
        "avg_ms": metric(data, "checkout_end_to_end_duration", "avg"),
        "p95_ms": metric(data, "checkout_end_to_end_duration", "p(95)"),
        "p99_ms": metric(data, "checkout_end_to_end_duration", "p(99)"),
        "error_percent": None,
        "confirmed_rate_percent": None,
        "docker_stats_sample_count": app.sample_count,
        "cpu_avg_percent": app.cpu_avg_percent,
        "cpu_p95_percent": app.cpu_p95_percent,
        "memory_baseline_mib": app.baseline_memory_mib,
        "memory_avg_mib": app.memory_avg_mib,
        "memory_peak_mib": app.memory_peak_mib,
        "memory_peak_delta_mib": app.memory_peak_delta_mib,
        "simulator_stats_sample_count": simulator.sample_count,
        "simulator_cpu_avg_percent": simulator.cpu_avg_percent,
        "simulator_memory_peak_mib": simulator.memory_peak_mib,
        "host_logical_cpus": host_logical_cpus,
        "jfr_recording_seconds": jfr_recording_seconds,
        "jfr_window_overhead_seconds": (
            jfr_recording_seconds - measured_seconds
            if jfr_recording_seconds is not None and measured_seconds is not None
            else None
        ),
        "jfr_process_cpu_avg_percent": jfr_cpu_host,
        "jfr_process_cpu_p95_percent": jfr_value(jfr, "process_cpu_p95_percent"),
        "jfr_cpu_one_core_percent": jfr_one_core_percent,
        "jfr_cpu_equivalent_cores": jfr_equivalent_cores,
        "jfr_allocation_pressure_mib_s": jfr_value(jfr, "allocation_pressure_mib_per_second"),
        "jfr_gc_count": jfr_value(jfr, "gc_count"),
        "jfr_gc_pause_total_ms": gc_pause_total_ms,
        "jfr_gc_pause_max_ms": jfr_value(jfr, "gc_pause_max_ms"),
        "jfr_gc_pause_ratio_percent": gc_pause_ratio,
        "jfr_platform_threads_avg": jfr_value(jfr, "active_threads_average"),
        "jfr_platform_threads_max": jfr_value(jfr, "active_threads_max"),
        # Backward-compatible aliases consumed by existing generated documents.
        "jfr_active_threads_avg": jfr_value(jfr, "active_threads_average"),
        "jfr_active_threads_max": jfr_value(jfr, "active_threads_max"),
        "jfr_thread_park_count": jfr_value(jfr, "thread_park_count"),
        "jfr_thread_park_total_ms": jfr_value(jfr, "thread_park_total_ms"),
        "jfr_monitor_enter_count": jfr_value(jfr, "monitor_enter_count"),
        "jfr_virtual_thread_pinned_count": jfr_value(jfr, "virtual_thread_pinned_count"),
        "jfr_virtual_thread_submit_failed_count": jfr_value(jfr, "virtual_thread_submit_failed_count"),
        "jfr_data_loss_event_count": jfr_value(jfr, "data_loss_event_count"),
    }
    failed = metric(data, "http_req_failed", "rate")
    confirmed = metric(data, "checkout_confirmed_rate", "rate")
    result["error_percent"] = None if failed is None else failed * 100
    result["confirmed_rate_percent"] = None if confirmed is None else confirmed * 100

    (run_dir / "run-summary.json").write_text(
        json.dumps(result, indent=2, allow_nan=False) + "\n", encoding="utf-8"
    )

    md = f"""# Evidence Run — `{result['run_id']}`

| Field | Value |
|---|---|
| Stack | `{result['stack']}` |
| Scenario | `{result['scenario']}` |
| Load model | `{load_model}` (`{semantics}`) |
| Pair / order / run | `{result['pair']} / {result['order']} / {result['run_number']}` |
| Workload seed | `{result['workload_seed']}` |
| Git SHA | `{result['git_sha']}` |

## HTTP and measured-window container summary

| Achieved req/s | Configured req/s | Schedule adherence % | Dropped iterations | Avg ms | p95 ms | p99 ms | Error % |
|---:|---:|---:|---:|---:|---:|---:|---:|
| {fmt(result['rps'])} | {fmt(configured_rate)} | {fmt(schedule_adherence)} | {fmt(dropped_iterations)} | {fmt(result['avg_ms'])} | {fmt(result['p95_ms'])} | {fmt(result['p99_ms'])} | {fmt(result['error_percent'])} |

| Docker samples | App CPU avg / p95 % | App memory baseline / avg / peak MiB | Peak delta MiB | Simulator CPU avg % | Simulator memory peak MiB |
|---:|---:|---:|---:|---:|---:|
| {app.sample_count} | {fmt(app.cpu_avg_percent)} / {fmt(app.cpu_p95_percent)} | {fmt(app.baseline_memory_mib)} / {fmt(app.memory_avg_mib)} / {fmt(app.memory_peak_mib)} | {fmt(app.memory_peak_delta_mib)} | {fmt(simulator.cpu_avg_percent)} | {fmt(simulator.memory_peak_mib)} |

## Structured JFR summary

| CPU host-capacity % | CPU one-core % | Equivalent cores | Allocation MiB/s | GC pause ratio % | Platform threads avg / max | VThread pinned | JFR data loss |
|---:|---:|---:|---:|---:|---:|---:|---:|
| {fmt(jfr_cpu_host)} | {fmt(jfr_one_core_percent)} | {fmt(jfr_equivalent_cores)} | {fmt(result['jfr_allocation_pressure_mib_s'])} | {fmt(gc_pause_ratio)} | {fmt(result['jfr_platform_threads_avg'])} / {fmt(result['jfr_platform_threads_max'])} | {fmt(result['jfr_virtual_thread_pinned_count'])} | {fmt(result['jfr_data_loss_event_count'])} |

`JVM CPU host-capacity %` is normalized across all {host_logical_cpus} logical CPUs. `CPU one-core %` is directly comparable to Docker's convention where one fully used core is 100%.

## Evidence integrity guardrails

- Docker stats are filtered to the exact `K6_STARTED_NS..K6_ENDED_NS` interval.
- The collector is joined before summary generation and before `manifest.sha256`.
- `dropped_iterations` must be zero for a valid formal run.
- Arrival-rate scenarios report schedule adherence, not maximum server capacity.
- The comparison is between complete application stacks, not an isolated Loom-versus-Reactor microbenchmark.

See `jfr-reports/JFR_METRICS.md` for allocation classes, sampled CPU methods, and concurrency observations.

This run is evidence for the documented environment only; it is not a universal benchmark.
"""
    (run_dir / "RUN_SUMMARY.md").write_text(md, encoding="utf-8")
    print(json.dumps(result, indent=2, allow_nan=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
