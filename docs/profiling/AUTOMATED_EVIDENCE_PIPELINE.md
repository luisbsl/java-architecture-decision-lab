# Automated Performance Evidence Pipeline

> **This is not a definitive benchmark.** The pipeline creates reproducible evidence for a documented machine, workload, commit, and profiler configuration.

## One measured run

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence.sh \
  --implementation mvc-vthreads \
  --scenario moderate \
  --pair 1 \
  --order 1 \
  --run-number 1
```

Equivalent WebFlux run:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence.sh \
  --implementation webflux-reactor \
  --scenario moderate \
  --pair 1 \
  --order 2 \
  --run-number 1
```

Each run automatically:

1. requires a clean Git worktree;
2. records commit, branch, host, JDK, Docker, CPU, memory, and effective Compose configuration;
3. starts only the simulator and the selected implementation;
4. uses a JDK-based evidence image with the same Java 21 runtime family for both implementations;
5. applies equal CPU and memory limits;
6. performs a fixed warm-up;
7. captures Actuator and JVM snapshots before load;
8. starts a bounded JFR recording with the repository evidence profile;
9. samples Docker CPU, memory, network, block I/O, and PIDs;
10. runs the selected k6 scenario;
11. captures post-load Actuator, thread, heap, class histogram, native-memory, logs, and container metadata;
12. generates JFR text views, a machine-readable summary, a Markdown summary, and SHA-256 manifest;
13. always removes containers unless `--keep-running` is provided.

Artifacts are written under:

```text
.artifacts/evidence/<RUN_ID>/
```

## Complete paired protocol

Run the default four-pair moderate protocol:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh
```

Run moderate and high scenarios:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \
  --scenarios moderate,high \
  --pairs 4
```


This full command schedules 16 isolated runs. It is not an infinite loop: the suite alternates order across each pair and then repeats the same protocol for the next scenario. The suite prints an estimate for the selected scenarios and pair count; actual elapsed time is host-dependent.

The runner pre-builds images once, prints a suite counter and k6 heartbeat, applies scenario-aware watchdogs, and pins both source and runtime/resource configuration fingerprints. Resume after interruption with:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \
  --scenarios moderate,high \
  --pairs 4 \
  --resume .artifacts/evidence/<SUITE_ID>-paired-evidence
```

See [`../troubleshooting/evidence-suite-progress-and-recovery.md`](../troubleshooting/evidence-suite-progress-and-recovery.md).

The order alternates to reduce systematic first-run bias:

```text
Pair 1: MVC -> WebFlux
Pair 2: WebFlux -> MVC
Pair 3: MVC -> WebFlux
```

The suite produces:

```text
COMPARISON.md
comparison.csv
suite-manifest.sha256
```

## Scenarios

| Scenario | Purpose | Default measured window |
|---|---|---:|
| `functional` | contract and evidence-pipeline smoke | one request |
| `moderate` | stable I/O-bound comparison | 60 s |
| `high` | ramping concurrency behavior | 120 s |
| `slow-payment` | degraded downstream and timeout investigation | 60 s |
| `intermittent-failures` | resilience and operational diagnosis | 60 s |

Failure-injection scenarios must not be mixed into the deterministic throughput table.

## Resource controls

Both implementations receive the same limits during automated evidence runs:

```bash
APP_CPUS=2.0 APP_MEMORY=1g \
  labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh
```

Record host power mode and avoid unrelated workloads. Docker limits make the protocol more comparable but do not turn a laptop into a production benchmark environment.

## Pipeline verification

```bash
./scripts/verify-evidence-tooling.sh
```

This checks shell syntax, Python tools and tests, the custom JFR configuration, and the Compose evidence override when Docker is available.

## Publishing policy

Commit only curated, small, sanitized evidence:

```text
docs/results/evidence/
```

Keep raw `k6-points`, `.jfr`, `.hprof`, full logs, and large snapshots under `.artifacts/` or attach them to a GitHub Release. Every published table must identify the source run IDs and Git SHA.

## Materialize documentation without copy and paste

After the suite completes:

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-docs \
  SUITE_DIR=.artifacts/evidence/<SUITE_ID> \
  UPDATE_ANALYSIS=1
```

This extracts structured JFR metrics, rebuilds normalized run summaries, generates comparative Markdown/JSON/CSV, exports the curated evidence tree, and updates only the managed evidence block in the main analysis. Manual interpretation remains outside generated markers.

See [`AUTOMATED_DOCUMENTATION_WORKFLOW.md`](AUTOMATED_DOCUMENTATION_WORKFLOW.md).

## Package and curate a completed suite

Create a complete release archive:

```bash
labs/01-loom-vs-reactive-checkout/scripts/package-evidence.sh \
  .artifacts/evidence/<SUITE_ID>
```

Export only small, reviewable files into the repository:

```bash
labs/01-loom-vs-reactive-checkout/scripts/export-curated-evidence.sh \
  .artifacts/evidence/<SUITE_ID>
```

The curated export excludes raw JFR, full logs, container inspection, heap dumps, and granular k6 streams. Attach the full `.tar.gz` to the GitHub Release and commit the curated directory only after review.

Upload the full archive to an existing or new GitHub Release:

```bash
labs/01-loom-vs-reactive-checkout/scripts/publish-evidence-release.sh \
  .artifacts/evidence/<SUITE_ID> \
  v1.0.0-evidence
```

The command verifies GitHub CLI authentication, packages the suite, creates the release when needed, and uploads the archive and checksum.

## Generated Mermaid projections

`materialize-evidence-docs.sh` also generates `EVIDENCE_CHARTS.md` from `comparison-aggregates.json`. The charts are review aids only; JSON, CSV, per-run summaries, and raw JFR remain authoritative.
