#!/usr/bin/env python3
"""Summarize a curated run CSV using only the Python standard library.

Expected columns:
implementation,scenario,rps,avg_ms,p95_ms,p99_ms,error_percent,cpu_avg,memory_peak_mb
"""

from __future__ import annotations

import argparse
import csv
import statistics
import sys
from collections import defaultdict
from pathlib import Path

NUMERIC_COLUMNS = (
    "rps",
    "avg_ms",
    "p95_ms",
    "p99_ms",
    "error_percent",
    "cpu_avg",
    "memory_peak_mb",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_file", type=Path)
    return parser.parse_args()


def as_float(row: dict[str, str], column: str, line_number: int) -> float:
    try:
        return float(row[column])
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError(f"line {line_number}: invalid {column!r}") from exc


def format_metric(values: list[float]) -> str:
    return f"{statistics.median(values):.3f} [{min(values):.3f},{max(values):.3f}]"


def main() -> int:
    args = parse_args()
    groups: dict[tuple[str, str], list[dict[str, float]]] = defaultdict(list)

    with args.csv_file.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        required = {"implementation", "scenario", *NUMERIC_COLUMNS}
        missing = required.difference(reader.fieldnames or ())
        if missing:
            raise ValueError(f"missing columns: {', '.join(sorted(missing))}")

        for line_number, row in enumerate(reader, start=2):
            key = (row["implementation"].strip(), row["scenario"].strip())
            groups[key].append(
                {column: as_float(row, column, line_number) for column in NUMERIC_COLUMNS}
            )

    print("| Implementation | Scenario | Runs | RPS median [min,max] | Avg ms | p95 ms | p99 ms | Error % | CPU avg | Memory peak MB |")
    print("|---|---|---:|---|---|---|---|---|---|---|")
    for (implementation, scenario), rows in sorted(groups.items()):
        metrics = {
            column: [row[column] for row in rows]
            for column in NUMERIC_COLUMNS
        }
        print(
            f"| {implementation} | {scenario} | {len(rows)} | "
            f"{format_metric(metrics['rps'])} | "
            f"{format_metric(metrics['avg_ms'])} | "
            f"{format_metric(metrics['p95_ms'])} | "
            f"{format_metric(metrics['p99_ms'])} | "
            f"{format_metric(metrics['error_percent'])} | "
            f"{format_metric(metrics['cpu_avg'])} | "
            f"{format_metric(metrics['memory_peak_mb'])} |"
        )

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        raise SystemExit(2)
