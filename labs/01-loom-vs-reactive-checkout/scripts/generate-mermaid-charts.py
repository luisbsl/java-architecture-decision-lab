#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate GitHub-renderable Mermaid charts from curated evidence aggregates."
    )
    parser.add_argument("curated_dir", type=Path)
    parser.add_argument("--output", type=Path)
    return parser.parse_args()


def median(groups: dict[tuple[str, str], dict[str, Any]], scenario: str, implementation: str, metric: str) -> float:
    value = groups[(scenario, implementation)][metric]["median"]
    return float(value)


def chart(title: str, y_title: str, values: list[float], maximum: float | None = None) -> str:
    ceiling = maximum if maximum is not None else max(values) * 1.15
    ceiling = max(ceiling, 1.0)
    formatted = ", ".join(f"{value:.3f}" for value in values)
    return "\n".join(
        [
            "```mermaid",
            "xychart-beta",
            f'    title "{title}"',
            '    x-axis ["Moderate MVC", "Moderate WebFlux", "High MVC", "High WebFlux"]',
            f'    y-axis "{y_title}" 0 --> {ceiling:.3f}',
            f"    bar [{formatted}]",
            "```",
        ]
    )


def main() -> int:
    args = parse_args()
    curated = args.curated_dir.resolve()
    source = curated / "comparison-aggregates.json"
    if not source.is_file():
        raise SystemExit(f"[ERROR] Missing aggregate source: {source}")
    document = json.loads(source.read_text(encoding="utf-8"))
    groups = {
        (item["scenario"], item["implementation"]): item
        for item in document["groups"]
    }
    order = [
        ("moderate", "mvc-vthreads"),
        ("moderate", "webflux-reactor"),
        ("high", "mvc-vthreads"),
        ("high", "webflux-reactor"),
    ]

    def values(metric: str) -> list[float]:
        return [median(groups, scenario, implementation, metric) for scenario, implementation in order]

    lines = [
        "# Generated Evidence Charts",
        "",
        f"- Suite: `{document['suite_id']}`",
        "- Canonical source: [`comparison-aggregates.json`](comparison-aggregates.json)",
        "- Semantics: medians across four isolated runs per implementation and scenario.",
        "- These diagrams are generated projections, not an independent evidence source.",
        "",
        "## p95 latency",
        "",
        chart("p95 latency", "milliseconds", values("p95_ms")),
        "",
        "## Application CPU",
        "",
        chart("Docker application CPU", "percent", values("cpu_avg_percent")),
        "",
        "## JFR allocation pressure",
        "",
        chart("JFR allocation pressure", "MiB per second", values("jfr_allocation_pressure_mib_s")),
        "",
        "## Measured-window memory growth",
        "",
        chart("Application memory peak delta", "MiB", values("memory_peak_delta_mib")),
        "",
        "## Maximum platform threads",
        "",
        chart("Maximum active platform threads", "threads", values("jfr_platform_threads_max")),
        "",
        "## Interpretation boundary",
        "",
        "Mermaid charts replace neither raw JFR nor structured JSON/CSV. They also cannot create missing incident-response, stack-trace, or human-debugging evidence.",
        "",
    ]
    output = args.output.resolve() if args.output else curated / "EVIDENCE_CHARTS.md"
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"[OK] Generated Mermaid evidence charts: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
