from __future__ import annotations

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parents[1]


def load_module(filename: str, name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPT_DIR / filename)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_summary(run: Path, implementation: str, order: int) -> None:
    result = {
        "run_id": run.name,
        "implementation": implementation,
        "scenario": "moderate",
        "pair": 1,
        "order": order,
        "run_number": 1,
        "git_sha": "abc123",
        "rps": 25.0 + order,
        "avg_ms": 100.0,
        "p95_ms": 200.0,
        "p99_ms": 300.0,
        "error_percent": 0.0,
        "confirmed_rate_percent": 100.0,
        "cpu_avg_percent": 20.0,
        "memory_peak_mib": 256.0,
        "jfr_recording_seconds": 60.0,
        "jfr_process_cpu_avg_percent": 10.0,
        "jfr_process_cpu_p95_percent": 20.0,
        "jfr_allocation_pressure_mib_s": 8.0,
        "jfr_gc_count": 4,
        "jfr_gc_pause_total_ms": 12.0,
        "jfr_gc_pause_max_ms": 5.0,
        "jfr_active_threads_avg": 30.0,
        "jfr_active_threads_max": 40,
        "jfr_thread_park_count": 100,
        "jfr_thread_park_total_ms": 200.0,
        "jfr_monitor_enter_count": 0,
        "jfr_virtual_thread_pinned_count": 0,
        "jfr_virtual_thread_submit_failed_count": 0,
        "jfr_data_loss_event_count": 0,
    }
    run.mkdir(parents=True)
    (run / "run-summary.json").write_text(json.dumps(result), encoding="utf-8")
    (run / "RUN_SUMMARY.md").write_text("# run\n", encoding="utf-8")
    (run / "run.env").write_text("GIT_SHA=abc123\n", encoding="utf-8")
    (run / "jfr-reports").mkdir()
    (run / "jfr-reports" / "jfr-metrics.json").write_text("{}", encoding="utf-8")
    (run / "jfr-reports" / "JFR_METRICS.md").write_text("# jfr\n", encoding="utf-8")
    (run / "load").mkdir()
    (run / "load" / "k6-summary.json").write_text("{}", encoding="utf-8")


class EvidenceToolsTests(unittest.TestCase):
    def test_memory_units_are_normalized_to_mib(self):
        module = load_module("build-run-summary.py", "build_run_summary")
        self.assertAlmostEqual(module.parse_memory("512MiB / 1GiB"), 512.0)
        self.assertAlmostEqual(module.parse_memory("1GiB / 2GiB"), 1024.0)

    def test_docker_metrics_are_bounded_to_the_exact_measured_window(self):
        module = load_module("build-run-summary.py", "build_run_summary_window")
        with tempfile.TemporaryDirectory() as tmp:
            stats = Path(tmp) / "docker-stats.csv"
            stats.write_text(
                "epoch_ns,utc,name,cpu_percent,memory_usage,net_io,block_io,pids\n"
                "50,now,arch-lab-mvc-virtual-threads,5.0%,100MiB / 1GiB,0B / 0B,0B / 0B,20\n"
                "100,now,arch-lab-mvc-virtual-threads,10.0%,200MiB / 1GiB,0B / 0B,0B / 0B,20\n"
                "200,now,arch-lab-mvc-virtual-threads,20.0%,220MiB / 1GiB,0B / 0B,0B / 0B,20\n"
                "300,now,arch-lab-mvc-virtual-threads,99.0%,900MiB / 1GiB,0B / 0B,0B / 0B,20\n",
                encoding="utf-8",
            )
            metrics = module.docker_metrics(
                stats, "mvc-virtual-threads", measured_start_ns=100, measured_end_ns=250
            )
            self.assertEqual(metrics.sample_count, 2)
            self.assertEqual(metrics.cpu_avg_percent, 15.0)
            self.assertEqual(metrics.baseline_memory_mib, 100.0)
            self.assertEqual(metrics.memory_peak_mib, 220.0)
            self.assertEqual(metrics.memory_peak_delta_mib, 120.0)

    def test_run_summary_is_generated_from_k6_docker_and_jfr_evidence(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = Path(tmp)
            (run / "load").mkdir()
            (run / "jfr-reports").mkdir()
            (run / "run.env").write_text(
                "RUN_ID=test\nIMPLEMENTATION=mvc-vthreads\nSCENARIO=moderate\n"
                "PAIR=1\nORDER=1\nRUN_NUMBER=1\nGIT_SHA=abc123\n",
                encoding="utf-8",
            )
            summary = {
                "metrics": {
                    "http_reqs": {"values": {"rate": 25.0}},
                    "checkout_end_to_end_duration": {
                        "values": {"avg": 100.0, "p(95)": 200.0, "p(99)": 300.0}
                    },
                    "http_req_failed": {"values": {"rate": 0.01}},
                    "checkout_confirmed_rate": {"values": {"rate": 0.99}},
                }
            }
            (run / "load" / "k6-summary.json").write_text(json.dumps(summary), encoding="utf-8")
            (run / "jfr-reports" / "jfr-metrics.json").write_text(
                json.dumps(
                    {
                        "recording_duration_seconds": 60.0,
                        "process_cpu_average_percent": 12.5,
                        "process_cpu_p95_percent": 20.0,
                        "allocation_pressure_mib_per_second": 7.5,
                        "gc_count": 3,
                        "gc_pause_total_ms": 10.0,
                        "gc_pause_max_ms": 4.0,
                        "active_threads_average": 25.0,
                        "active_threads_max": 30,
                        "thread_park_count": 10,
                        "thread_park_total_ms": 50.0,
                        "monitor_enter_count": 0,
                        "virtual_thread_pinned_count": 0,
                        "virtual_thread_submit_failed_count": 0,
                        "data_loss_event_count": 0,
                    }
                ),
                encoding="utf-8",
            )
            (run / "docker-stats.csv").write_text(
                "utc,name,cpu_percent,memory_usage,net_io,block_io,pids\n"
                "now,arch-lab-mvc-virtual-threads,25.0%,256MiB / 1GiB,0B / 0B,0B / 0B,20\n",
                encoding="utf-8",
            )
            subprocess.run(
                ["python3", str(SCRIPT_DIR / "build-run-summary.py"), str(run)],
                check=True,
                capture_output=True,
                text=True,
            )
            result = json.loads((run / "run-summary.json").read_text(encoding="utf-8"))
            self.assertEqual(result["rps"], 25.0)
            self.assertEqual(result["p99_ms"], 300.0)
            self.assertEqual(result["cpu_avg_percent"], 25.0)
            self.assertEqual(result["memory_peak_mib"], 256.0)
            self.assertEqual(result["jfr_process_cpu_avg_percent"], 12.5)
            self.assertEqual(result["jfr_allocation_pressure_mib_s"], 7.5)

    def test_controlled_arrival_rate_accepts_one_boundary_iteration_delta(self):
        module = load_module("audit-evidence-suite.py", "audit_boundary_tolerance")
        mvc = {
            "load_model": "constant-arrival-rate",
            "configured_rate_rps": 25.0,
            "_measured_seconds": 60.0,
            "iterations": 1500.0,
        }
        webflux = {
            "load_model": "constant-arrival-rate",
            "configured_rate_rps": 25.0,
            "_measured_seconds": 60.0,
            "iterations": 1501.0,
        }
        errors, warnings = module.controlled_workload_pair_issues(
            mvc, webflux, "moderate", 2
        )
        self.assertEqual(errors, [])
        self.assertEqual(
            warnings,
            ["controlled_workload_boundary_iteration_delta:moderate:2:delta=1"],
        )

    def test_controlled_arrival_rate_rejects_delta_beyond_boundary_tolerance(self):
        module = load_module("audit-evidence-suite.py", "audit_boundary_rejection")
        mvc = {
            "load_model": "constant-arrival-rate",
            "configured_rate_rps": 25.0,
            "_measured_seconds": 60.0,
            "iterations": 1500.0,
        }
        webflux = {
            "load_model": "constant-arrival-rate",
            "configured_rate_rps": 25.0,
            "_measured_seconds": 60.0,
            "iterations": 1502.0,
        }
        errors, warnings = module.controlled_workload_pair_issues(
            mvc, webflux, "moderate", 2
        )
        self.assertEqual(
            errors,
            ["controlled_workload_expected_iteration_mismatch:moderate:2"],
        )
        self.assertEqual(warnings, [])

    def test_aggregate_and_documentation_are_generated_without_copy_paste(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            suite = root / "suite"
            suite.mkdir()
            (suite / "suite.env").write_text(
                "SUITE_ID=suite\nSCENARIOS=moderate\nPAIRS=1\nPROTOCOL_VERSION=3\nPROTOCOL_FINGERPRINT=test-fingerprint\nGIT_SHA=abc123\n",
                encoding="utf-8",
            )
            write_summary(suite / "mvc-run", "mvc-vthreads", 1)
            write_summary(suite / "webflux-run", "webflux-reactor", 2)

            subprocess.run(
                ["python3", str(SCRIPT_DIR / "aggregate-evidence.py"), str(suite)],
                check=True,
                capture_output=True,
                text=True,
            )
            aggregate = json.loads((suite / "comparison-aggregates.json").read_text(encoding="utf-8"))
            self.assertEqual(aggregate["status"], "complete")
            self.assertEqual(aggregate["completed_runs"], 2)

            analysis = root / "analysis.md"
            analysis.write_text(
                "# Analysis\n\n> **Measurement status: not executed yet.**\n\n"
                "## Quantitative evidence\n\nLegacy empty tables.\n\n"
                "## JVM and profiler observations\n\nManual content.\n",
                encoding="utf-8",
            )
            output_root = root / "published"
            subprocess.run(
                [
                    "python3",
                    str(SCRIPT_DIR / "generate-evidence-docs.py"),
                    str(suite),
                    "--output-root",
                    str(output_root),
                    "--analysis",
                    str(analysis),
                    "--update-analysis",
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertTrue((output_root / "suite" / "README.md").exists())
            self.assertTrue((output_root / "suite" / "curated-manifest.sha256").exists())
            self.assertTrue((output_root / "suite" / "FACTUAL_OBSERVATIONS.md").exists())
            self.assertTrue((output_root / "LATEST.md").exists())
            updated = analysis.read_text(encoding="utf-8")
            self.assertIn("BEGIN AUTO-GENERATED:EVIDENCE", updated)
            self.assertIn("BEGIN AUTO-GENERATED:QUANTITATIVE-EVIDENCE", updated)
            self.assertIn("BEGIN AUTO-GENERATED:FACTUAL-OBSERVATIONS", updated)
            self.assertIn("Measurement status: complete (2/2 runs)", updated)
            self.assertNotIn("Legacy empty tables.", updated)
            self.assertIn("Manual content.", updated)

            validation = subprocess.run(
                [
                    "bash",
                    str(SCRIPT_DIR / "validate-curated-evidence.sh"),
                    str(output_root / "suite"),
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertIn("Curated evidence integrity validated", validation.stdout)


if __name__ == "__main__":
    unittest.main()
