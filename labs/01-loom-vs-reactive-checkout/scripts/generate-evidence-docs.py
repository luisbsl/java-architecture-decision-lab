#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import math
import shutil
from pathlib import Path
from typing import Any

BEGIN_MARKER = "<!-- BEGIN AUTO-GENERATED:EVIDENCE -->"
END_MARKER = "<!-- END AUTO-GENERATED:EVIDENCE -->"
QUANT_BEGIN_MARKER = "<!-- BEGIN AUTO-GENERATED:QUANTITATIVE-EVIDENCE -->"
QUANT_END_MARKER = "<!-- END AUTO-GENERATED:QUANTITATIVE-EVIDENCE -->"
FACTS_BEGIN_MARKER = "<!-- BEGIN AUTO-GENERATED:FACTUAL-OBSERVATIONS -->"
FACTS_END_MARKER = "<!-- END AUTO-GENERATED:FACTUAL-OBSERVATIONS -->"
STATUS_PREFIX = "> **Measurement status: "

RUN_FILES = (
    "run.env",
    "RUN_SUMMARY.md",
    "run-summary.json",
    "docker-stats.csv",
)
JFR_REPORTS = (
    "jfr-metrics.json",
    "JFR_METRICS.md",
    "summary.txt",
    "hot-methods.txt",
    "allocation-by-class.txt",
    "allocation-by-site.txt",
    "gc.txt",
    "gc-pauses.txt",
    "thread-count.txt",
    "thread-cpu-load.txt",
    "pinned-threads.txt",
    "concurrency-event-counts.txt",
)

IMPLEMENTATION_LABELS = {
    "mvc-vthreads": "MVC + Virtual Threads",
    "webflux-reactor": "WebFlux/Reactor",
}


class AnalysisUpdateError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate curated, linked Markdown evidence from a completed suite."
    )
    parser.add_argument("suite_dir", type=Path)
    parser.add_argument("--output-root", type=Path)
    parser.add_argument("--analysis", type=Path)
    parser.add_argument("--update-analysis", action="store_true")
    parser.add_argument("--allow-partial", action="store_true")
    parser.add_argument("--allow-unknown-git", action="store_true")
    return parser.parse_args()


def read_env(path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    if not path.exists():
        return env
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            env[key] = value
    return env


def finite(value: Any) -> float | None:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) else None


def percent_delta(candidate: Any, baseline: Any) -> float | None:
    left = finite(candidate)
    right = finite(baseline)
    if left is None or right in (None, 0.0):
        return None
    return (left - right) / right * 100.0


def format_delta(value: float | None) -> str:
    if value is None:
        return "n/a"
    return f"{value:+.2f}%"


def fmt_value(value: Any, decimals: int = 3) -> str:
    number = finite(value)
    if number is None:
        return "n/a"
    return f"{number:.{decimals}f}"


def fmt_stat(stat: Any, decimals: int = 3) -> str:
    if not isinstance(stat, dict) or not stat.get("count"):
        return "n/a"
    median = finite(stat.get("median"))
    minimum = finite(stat.get("min"))
    maximum = finite(stat.get("max"))
    if median is None or minimum is None or maximum is None:
        return "n/a"
    return f"{median:.{decimals}f} [{minimum:.{decimals}f}, {maximum:.{decimals}f}]"


def copy_if_exists(source: Path, target: Path) -> None:
    if source.is_file():
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def render_reproduction(suite_env: dict[str, str]) -> str:
    scenarios = suite_env.get("SCENARIOS", "moderate")
    pairs = suite_env.get("PAIRS", "3")
    return (
        "```bash\n"
        "labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \\\n"
        f"  --scenarios {scenarios} \\\n"
        f"  --pairs {pairs}\n"
        "```"
    )


def group_index(aggregate: dict[str, Any]) -> dict[tuple[str, str], dict[str, Any]]:
    return {
        (group["implementation"], group["scenario"]): group
        for group in aggregate.get("groups", [])
    }


def median(group: dict[str, Any] | None, metric: str) -> float | None:
    if not group:
        return None
    value = group.get(metric)
    if not isinstance(value, dict):
        return None
    return finite(value.get("median"))


def direction_statement(
    scenario: str,
    metric_label: str,
    webflux_value: float | None,
    mvc_value: float | None,
    unit: str,
) -> str:
    delta = percent_delta(webflux_value, mvc_value)
    if delta is None or webflux_value is None or mvc_value is None:
        return f"- **{scenario} — {metric_label}:** insufficient structured data for a paired median comparison."
    suffix = f" {unit}" if unit else ""
    if abs(delta) < 0.005:
        relation = "approximately equal to"
        delta_text = "0.00% difference"
    elif delta > 0:
        relation = "higher than"
        delta_text = f"{abs(delta):.2f}% higher"
    else:
        relation = "lower than"
        delta_text = f"{abs(delta):.2f}% lower"
    return (
        f"- **{scenario} — {metric_label}:** WebFlux median was {relation} MVC "
        f"({webflux_value:.3f}{suffix} vs {mvc_value:.3f}{suffix}; {delta_text})."
    )


def render_quantitative_block(
    output_name: str,
    aggregate: dict[str, Any],
    records: list[dict[str, Any]],
) -> str:
    lines = [
        QUANT_BEGIN_MARKER,
        "> Generated from committed `run-summary.json` files. Do not copy values from terminal output or profiler screenshots.",
        "",
        "### Per-run measurements",
        "",
        "| Pair | Order | Run | Implementation | Scenario | Achieved req/s | Dropped | Avg ms | p95 ms | p99 ms | Error % | Docker CPU % | Memory peak delta MiB | JFR CPU one-core % | Allocation MiB/s | Platform threads max | VThread pinned |",
        "|---:|---:|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for record in records:
        run_id = record["run_id"]
        label = IMPLEMENTATION_LABELS.get(record["implementation"], record["implementation"])
        lines.append(
            f"| {record['pair']} | {record['order']} | "
            f"[`{run_id}`](evidence/{output_name}/runs/{run_id}/RUN_SUMMARY.md) | "
            f"{label} | {record['scenario']} | {fmt_value(record.get('rps'))} | "
            f"{fmt_value(record.get('dropped_iterations'), 0)} | {fmt_value(record.get('avg_ms'))} | {fmt_value(record.get('p95_ms'))} | "
            f"{fmt_value(record.get('p99_ms'))} | {fmt_value(record.get('error_percent'))} | "
            f"{fmt_value(record.get('cpu_avg_percent'))} | {fmt_value(record.get('memory_peak_delta_mib', record.get('memory_peak_mib')))} | "
            f"{fmt_value(record.get('jfr_cpu_one_core_percent', record.get('jfr_process_cpu_avg_percent')))} | "
            f"{fmt_value(record.get('jfr_allocation_pressure_mib_s'))} | "
            f"{fmt_value(record.get('jfr_platform_threads_max', record.get('jfr_active_threads_max')), 0)} | "
            f"{fmt_value(record.get('jfr_virtual_thread_pinned_count'), 0)} |"
        )

    lines.extend(
        [
            "",
            "### Aggregated view",
            "",
            "> Values are median `[min, max]` across repetitions. The generator never selects only the best run.",
            "",
            "| Implementation | Scenario | Runs | Achieved req/s | Dropped | p95 ms | p99 ms | Error % | Docker CPU % | Memory peak delta MiB | JFR CPU one-core % | Allocation MiB/s | GC pause ratio % | Platform threads max | VThread pinned | JFR data loss |",
            "|---|---|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|",
        ]
    )
    for group in aggregate.get("groups", []):
        label = IMPLEMENTATION_LABELS.get(group["implementation"], group["implementation"])
        lines.append(
            f"| {label} | {group['scenario']} | {group['runs']} | "
            f"{fmt_stat(group.get('rps'))} | {fmt_stat(group.get('dropped_iterations'), 0)} | {fmt_stat(group.get('p95_ms'))} | "
            f"{fmt_stat(group.get('p99_ms'))} | {fmt_stat(group.get('error_percent'))} | "
            f"{fmt_stat(group.get('cpu_avg_percent'))} | {fmt_stat(group.get('memory_peak_delta_mib') or group.get('memory_peak_mib'))} | "
            f"{fmt_stat(group.get('jfr_cpu_one_core_percent') or group.get('jfr_process_cpu_avg_percent'))} | "
            f"{fmt_stat(group.get('jfr_allocation_pressure_mib_s'))} | "
            f"{fmt_stat(group.get('jfr_gc_pause_ratio_percent') or group.get('jfr_gc_pause_total_ms'))} | "
            f"{fmt_stat(group.get('jfr_platform_threads_max') or group.get('jfr_active_threads_max'), 0)} | "
            f"{fmt_stat(group.get('jfr_virtual_thread_pinned_count'), 0)} | "
            f"{fmt_stat(group.get('jfr_data_loss_event_count'), 0)} |"
        )
    lines.extend(
        [
            "",
            f"Full comparison: [`COMPARISON.md`](evidence/{output_name}/COMPARISON.md). "
            f"Machine-readable source: [`comparison-aggregates.json`](evidence/{output_name}/comparison-aggregates.json).",
            QUANT_END_MARKER,
        ]
    )
    return "\n".join(lines)


def render_factual_observations_body(
    output_name: str,
    aggregate: dict[str, Any],
    records: list[dict[str, Any]],
    *,
    from_analysis: bool,
) -> str:
    by_key = group_index(aggregate)
    scenarios = sorted({record["scenario"] for record in records})
    lines = [
        "> Generated observations describe measured medians only. They intentionally avoid causal explanations and architectural recommendations.",
        "",
    ]
    metrics = (
        ("achieved request rate", "rps", "req/s"),
        ("p95 latency", "p95_ms", "ms"),
        ("p99 latency", "p99_ms", "ms"),
        ("Docker CPU", "cpu_avg_percent", "%"),
        ("container memory peak delta", "memory_peak_delta_mib", "MiB"),
        ("JFR CPU in one-core convention", "jfr_cpu_one_core_percent", "%"),
        ("allocation pressure", "jfr_allocation_pressure_mib_s", "MiB/s"),
        ("GC pause ratio", "jfr_gc_pause_ratio_percent", "%"),
        ("maximum active platform threads", "jfr_platform_threads_max", "threads"),
    )
    for scenario in scenarios:
        mvc = by_key.get(("mvc-vthreads", scenario))
        webflux = by_key.get(("webflux-reactor", scenario))
        lines.append(f"### Scenario `{scenario}`")
        lines.append("")
        for metric_label, metric_key, unit in metrics:
            lines.append(
                direction_statement(
                    scenario,
                    metric_label,
                    median(webflux, metric_key),
                    median(mvc, metric_key),
                    unit,
                )
            )

        mvc_pinned = median(mvc, "jfr_virtual_thread_pinned_count")
        webflux_pinned = median(webflux, "jfr_virtual_thread_pinned_count")
        mvc_loss = median(mvc, "jfr_data_loss_event_count")
        webflux_loss = median(webflux, "jfr_data_loss_event_count")
        mvc_error = median(mvc, "error_percent")
        webflux_error = median(webflux, "error_percent")
        lines.extend(
            [
                f"- **{scenario} — error rate:** MVC median `{fmt_value(mvc_error)}%`; WebFlux median `{fmt_value(webflux_error)}%`.",
                f"- **{scenario} — Virtual Thread pinning events:** MVC median `{fmt_value(mvc_pinned, 0)}`; WebFlux median `{fmt_value(webflux_pinned, 0)}`.",
                f"- **{scenario} — JFR data-loss events:** MVC median `{fmt_value(mvc_loss, 0)}`; WebFlux median `{fmt_value(webflux_loss, 0)}`.",
                "",
            ]
        )

    prefix = f"evidence/{output_name}/" if from_analysis else ""
    lines.extend(
        [
            "Supporting artifacts:",
            "",
            f"- [`COMPARISON.md`]({prefix}COMPARISON.md)",
            f"- [`comparison-aggregates.json`]({prefix}comparison-aggregates.json)",
            f"- [Per-run documents]({prefix}README.md#run-documents)",
        ]
    )
    return "\n".join(lines)


def render_factual_observations_block(
    output_name: str,
    aggregate: dict[str, Any],
    records: list[dict[str, Any]],
) -> str:
    return "\n".join(
        [
            FACTS_BEGIN_MARKER,
            render_factual_observations_body(output_name, aggregate, records, from_analysis=True),
            FACTS_END_MARKER,
        ]
    )


def write_factual_observations(
    output: Path,
    output_name: str,
    aggregate: dict[str, Any],
    records: list[dict[str, Any]],
) -> None:
    content = "\n".join(
        [
            "# Automatically Generated Factual Observations",
            "",
            render_factual_observations_body(output_name, aggregate, records, from_analysis=False),
            "",
            "## Human review boundary",
            "",
            "The generator does not write causal inference, alternative explanations, limitations, or architectural decisions. Add those to `docs/results/01-loom-vs-reactive-analysis.md` after reviewing the raw and curated evidence.",
            "",
        ]
    )
    (output / "FACTUAL_OBSERVATIONS.md").write_text(content, encoding="utf-8")


def write_readme(
    output: Path,
    suite: Path,
    suite_env: dict[str, str],
    aggregate: dict[str, Any],
    records: list[dict[str, Any]],
) -> str:
    groups = aggregate.get("groups", [])
    by_key = {(g["implementation"], g["scenario"]): g for g in groups}
    scenarios = sorted({record["scenario"] for record in records})

    lines = [
        f"# Curated Evidence — `{suite.name}`",
        "",
        "> Generated automatically from immutable run summaries and structured JFR metrics. Do not edit generated tables manually.",
        "",
        "## Publication status",
        "",
        f"- Status: **{aggregate.get('status', 'unknown')}**",
        f"- Completed runs: **{aggregate.get('completed_runs', len(records))}**"
        + (
            f" / **{aggregate['expected_runs']}**"
            if aggregate.get("expected_runs") is not None
            else ""
        ),
        f"- Suite ID: `{suite.name}`",
        f"- Git SHA: `{suite_env.get('GIT_SHA', 'unknown')}`",
        f"- Protocol version: `{suite_env.get('PROTOCOL_VERSION', 'unknown')}`",
        f"- Protocol fingerprint: `{suite_env.get('PROTOCOL_FINGERPRINT', 'unknown')}`",
        f"- Scenarios: `{suite_env.get('SCENARIOS', 'unknown')}`",
        f"- Pairs: `{suite_env.get('PAIRS', 'unknown')}`",
        "",
        "## Reproduce",
        "",
        render_reproduction(suite_env),
        "",
        "## Generated comparison",
        "",
        "- [`COMPARISON.md`](COMPARISON.md): full HTTP, container, JVM, GC, allocation, thread, and pinning tables.",
        "- [`FACTUAL_OBSERVATIONS.md`](FACTUAL_OBSERVATIONS.md): neutral, automatically generated comparisons without causal claims.",
        "",
        "## Observed median deltas",
        "",
        "These deltas describe this machine, commit, scenario, limits, and profiler configuration. They are observations, not universal conclusions.",
        "",
        "| Scenario | WebFlux vs MVC achieved req/s | WebFlux vs MVC p95 | WebFlux vs MVC JFR CPU one-core | WebFlux vs MVC allocation pressure |",
        "|---|---:|---:|---:|---:|",
    ]
    for scenario in scenarios:
        mvc = by_key.get(("mvc-vthreads", scenario))
        webflux = by_key.get(("webflux-reactor", scenario))
        if not mvc or not webflux:
            lines.append(f"| {scenario} | n/a | n/a | n/a | n/a |")
            continue

        lines.append(
            f"| {scenario} | "
            f"{format_delta(percent_delta(median(webflux, 'rps'), median(mvc, 'rps')))} | "
            f"{format_delta(percent_delta(median(webflux, 'p95_ms'), median(mvc, 'p95_ms')))} | "
            f"{format_delta(percent_delta(median(webflux, 'jfr_cpu_one_core_percent'), median(mvc, 'jfr_cpu_one_core_percent')))} | "
            f"{format_delta(percent_delta(median(webflux, 'jfr_allocation_pressure_mib_s'), median(mvc, 'jfr_allocation_pressure_mib_s')))} |"
        )

    lines.extend(
        [
            "",
            "## Run documents",
            "",
            "| Pair | Order | Implementation | Scenario | Run | JFR details |",
            "|---:|---:|---|---|---|---|",
        ]
    )
    for record in records:
        run_id = record["run_id"]
        lines.append(
            f"| {record['pair']} | {record['order']} | {record['implementation']} | "
            f"{record['scenario']} | [`{run_id}`](runs/{run_id}/RUN_SUMMARY.md) | "
            f"[JFR](runs/{run_id}/jfr-reports/JFR_METRICS.md) |"
        )

    lines.extend(
        [
            "",
            "## Evidence policy",
            "",
            "- Raw `.jfr`, full logs, granular k6 streams, heap dumps, and container inspection remain release assets.",
            "- Per-run `source-manifest.sha256` is provenance for the raw package; validate the curated tree with `curated-manifest.sha256`.",
            "- Published tables are generated from `run-summary.json` and `jfr-metrics.json`.",
            "- VisualVM/JMC screenshots may supplement interpretation, but they are not the numeric source of truth.",
            "- Manual analysis belongs in `docs/results/01-loom-vs-reactive-analysis.md`, outside generated markers.",
            "",
            "## Guardrails",
            "",
            "- Allocation pressure uses JFR sample weight and is not retained heap.",
            "- Sampling identifies observed hotspots; it does not prove causality by itself.",
            "- No pinned-thread event means none was observed above the configured threshold during the measured window.",
            "- Arrival-rate request rates describe schedule adherence, not maximum server capacity.",
            "- The comparison is between complete stacks, not an isolated Loom-versus-Reactor microbenchmark.",
            "- A local profiler-enabled protocol does not represent every production environment.",
        ]
    )
    content = "\n".join(lines) + "\n"
    (output / "README.md").write_text(content, encoding="utf-8")
    return content


def write_manifest(output: Path) -> None:
    rows: list[str] = []
    for path in sorted(output.rglob("*")):
        if not path.is_file() or path.name == "curated-manifest.sha256":
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        rows.append(f"{digest}  {path.relative_to(output).as_posix()}")
    (output / "curated-manifest.sha256").write_text("\n".join(rows) + "\n", encoding="utf-8")


def managed_block(output_name: str, aggregate: dict[str, Any]) -> str:
    status = aggregate.get("status", "unknown")
    completed = aggregate.get("completed_runs", "unknown")
    expected = aggregate.get("expected_runs")
    run_label = str(completed) + (f"/{expected}" if expected is not None else "")
    return "\n".join(
        [
            BEGIN_MARKER,
            "## Latest generated evidence",
            "",
            "> This section is updated by `materialize-evidence-docs.sh`. Write hypotheses, interpretation, alternative explanations, and decisions outside these markers.",
            "",
            f"- Evidence set: [`{output_name}`](evidence/{output_name}/README.md)",
            f"- Status: **{status}**",
            f"- Completed runs: **{run_label}**",
            f"- Comparative tables: [`COMPARISON.md`](evidence/{output_name}/COMPARISON.md)",
            f"- Factual observations: [`FACTUAL_OBSERVATIONS.md`](evidence/{output_name}/FACTUAL_OBSERVATIONS.md)",
            f"- Machine-readable aggregates: [`comparison-aggregates.json`](evidence/{output_name}/comparison-aggregates.json)",
            "",
            "Numeric tables are generated from k6, Docker Stats, and bounded JFR recordings. VisualVM/JMC is used for optional offline interpretation of the same raw recordings.",
            END_MARKER,
        ]
    )


def replace_marked_block(content: str, begin: str, end: str, block: str) -> str:
    if (begin in content) != (end in content):
        raise AnalysisUpdateError(f"Unbalanced managed markers: {begin} / {end}")
    if begin in content:
        start = content.index(begin)
        finish = content.index(end, start) + len(end)
        return content[:start] + block + content[finish:]
    return content


def replace_section(
    content: str,
    heading: str,
    next_heading: str,
    replacement: str,
) -> str:
    start = content.find(heading)
    if start < 0:
        raise AnalysisUpdateError(f"Analysis heading not found: {heading}")
    finish = content.find(next_heading, start + len(heading))
    if finish < 0:
        raise AnalysisUpdateError(f"Next analysis heading not found: {next_heading}")
    return content[:start] + replacement.rstrip() + "\n\n" + content[finish:]


def ensure_factual_section(content: str, block: str) -> str:
    heading = "## Automatically generated factual observations"
    next_heading = "## JVM and profiler observations"
    if FACTS_BEGIN_MARKER in content or heading in content:
        if FACTS_BEGIN_MARKER in content:
            return replace_marked_block(content, FACTS_BEGIN_MARKER, FACTS_END_MARKER, block)
        return replace_section(content, heading, next_heading, heading + "\n\n" + block)
    anchor = content.find(next_heading)
    if anchor < 0:
        raise AnalysisUpdateError(f"Analysis anchor not found: {next_heading}")
    return content[:anchor] + heading + "\n\n" + block + "\n\n" + content[anchor:]


def update_status(content: str, aggregate: dict[str, Any]) -> str:
    status = aggregate.get("status", "unknown")
    completed = aggregate.get("completed_runs", "unknown")
    expected = aggregate.get("expected_runs")
    run_label = str(completed) + (f"/{expected}" if expected is not None else "")
    replacement = f"> **Measurement status: {status} ({run_label} runs).**"
    lines = content.splitlines()
    for index, line in enumerate(lines):
        if line.startswith(STATUS_PREFIX):
            lines[index] = replacement
            return "\n".join(lines) + "\n"
    title_index = next((i for i, line in enumerate(lines) if line.startswith("# ")), None)
    if title_index is None:
        raise AnalysisUpdateError("Analysis title not found")
    lines[title_index + 1:title_index + 1] = ["", replacement]
    return "\n".join(lines) + "\n"


def update_analysis(
    path: Path,
    overview_block: str,
    quantitative_block: str,
    factual_block: str,
    aggregate: dict[str, Any],
) -> None:
    content = path.read_text(encoding="utf-8")

    if BEGIN_MARKER in content:
        content = replace_marked_block(content, BEGIN_MARKER, END_MARKER, overview_block)
    else:
        anchor = "## Quantitative evidence"
        if anchor not in content:
            raise AnalysisUpdateError(f"Analysis anchor not found: {anchor}")
        content = content.replace(anchor, overview_block + "\n\n" + anchor, 1)

    quantitative_heading = "## Quantitative evidence"
    jvm_heading = "## JVM and profiler observations"
    if QUANT_BEGIN_MARKER in content:
        content = replace_marked_block(
            content,
            QUANT_BEGIN_MARKER,
            QUANT_END_MARKER,
            quantitative_block,
        )
    else:
        content = replace_section(
            content,
            quantitative_heading,
            jvm_heading,
            quantitative_heading + "\n\n" + quantitative_block,
        )

    content = ensure_factual_section(content, factual_block)
    content = update_status(content, aggregate)
    path.write_text(content, encoding="utf-8")


def write_latest_pointer(output_root: Path, output_name: str, aggregate: dict[str, Any]) -> None:
    completed = aggregate.get("completed_runs", "unknown")
    expected = aggregate.get("expected_runs")
    run_label = str(completed) + (f"/{expected}" if expected is not None else "")
    content = "\n".join(
        [
            "# Latest Curated Evidence",
            "",
            f"- Suite: [`{output_name}`]({output_name}/README.md)",
            f"- Status: **{aggregate.get('status', 'unknown')}**",
            f"- Completed runs: **{run_label}**",
            f"- Integrity manifest: [`curated-manifest.sha256`]({output_name}/curated-manifest.sha256)",
            "",
            "Validate locally:",
            "",
            "```bash",
            "make -C labs/01-loom-vs-reactive-checkout evidence-validate",
            "```",
            "",
        ]
    )
    (output_root / "LATEST.md").write_text(content, encoding="utf-8")


def main() -> int:
    args = parse_args()
    suite = args.suite_dir.resolve()
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parents[2]
    output_root = (args.output_root or repo_root / "docs/results/evidence").resolve()
    analysis = (args.analysis or repo_root / "docs/results/01-loom-vs-reactive-analysis.md").resolve()

    aggregate_path = suite / "comparison-aggregates.json"
    comparison_path = suite / "COMPARISON.md"
    if not aggregate_path.exists() or not comparison_path.exists():
        raise SystemExit("[ERROR] Aggregate the suite before generating documentation")

    aggregate = json.loads(aggregate_path.read_text(encoding="utf-8"))
    if aggregate.get("status") != "complete" and not args.allow_partial:
        raise SystemExit(
            "[ERROR] Suite is partial. Use --allow-partial only for a diagnostic preview; do not publish it as final evidence."
        )

    records = [
        json.loads(path.read_text(encoding="utf-8"))
        for path in sorted(suite.rglob("run-summary.json"))
    ]
    records.sort(key=lambda row: (row["scenario"], int(row["pair"]), int(row["order"])))
    suite_env = read_env(suite / "suite.env")
    unknown_git = [record["run_id"] for record in records if record.get("git_sha") in (None, "", "unknown")]
    if unknown_git and not args.allow_unknown_git:
        raise SystemExit(
            "[ERROR] Formal evidence requires a Git SHA. Unknown in: " + ", ".join(unknown_git)
        )
    known_git_shas = {str(record.get("git_sha")) for record in records if record.get("git_sha") not in (None, "", "unknown")}
    if len(known_git_shas) > 1:
        raise SystemExit("[ERROR] Runs from different Git SHAs cannot be published together: " + ", ".join(sorted(known_git_shas)))
    suite_git_sha = suite_env.get("GIT_SHA")
    if suite_git_sha not in (None, "", "unknown") and known_git_shas and suite_git_sha not in known_git_shas:
        raise SystemExit(
            f"[ERROR] suite.env Git SHA {suite_git_sha} differs from run Git SHA {next(iter(known_git_shas))}"
        )
    if not args.allow_unknown_git:
        for required in ("PROTOCOL_VERSION", "PROTOCOL_FINGERPRINT", "GIT_SHA"):
            if suite_env.get(required) in (None, "", "unknown"):
                raise SystemExit(f"[ERROR] Formal evidence suite is missing {required} in suite.env")

    output = output_root / suite.name
    if output.exists():
        shutil.rmtree(output)
    (output / "runs").mkdir(parents=True)

    for filename in ("COMPARISON.md", "comparison.csv", "comparison-aggregates.json", "suite.env", "suite-manifest.sha256", "SUITE_AUDIT.md", "suite-audit.json"):
        copy_if_exists(suite / filename, output / filename)

    for record in records:
        run_id = record["run_id"]
        run_dir = suite / run_id
        target = output / "runs" / run_id
        for filename in RUN_FILES:
            copy_if_exists(run_dir / filename, target / filename)
        # Preserve the raw manifest only as source provenance. The curated tree intentionally
        # omits large raw artifacts, so validation is provided by curated-manifest.sha256.
        copy_if_exists(run_dir / "manifest.sha256", target / "source-manifest.sha256")
        copy_if_exists(run_dir / "load/k6-summary.json", target / "load/k6-summary.json")
        for filename in JFR_REPORTS:
            copy_if_exists(run_dir / "jfr-reports" / filename, target / "jfr-reports" / filename)

    write_readme(output, suite, suite_env, aggregate, records)
    write_factual_observations(output, suite.name, aggregate, records)
    write_manifest(output)
    write_latest_pointer(output_root, suite.name, aggregate)

    if args.update_analysis:
        if aggregate.get("status") != "complete" and not args.allow_partial:
            raise SystemExit("[ERROR] Refusing to update analysis from partial evidence")
        try:
            update_analysis(
                analysis,
                managed_block(suite.name, aggregate),
                render_quantitative_block(suite.name, aggregate, records),
                render_factual_observations_block(suite.name, aggregate, records),
                aggregate,
            )
        except AnalysisUpdateError as exc:
            raise SystemExit(f"[ERROR] {exc}") from exc
        print(f"[OK] Updated managed evidence blocks: {analysis}")

    print(f"[OK] Curated evidence documentation: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
