# Benchmark Protocol — Publication-Grade Evidence

> **This is not a definitive benchmark.** The lab compares complete Spring application stacks under a documented local, profiler-enabled protocol.

## 1. Acceptance gates

A suite is publishable only when all gates pass:

- clean Git worktree and one immutable Git SHA;
- current protocol version 5, one locale-stable source fingerprint, and one runtime/resource configuration fingerprint;
- even pair count, minimum 4;
- balanced order: equal MVC-first and WebFlux-first pairs;
- deterministic workload seed and simulator behavior;
- zero dropped iterations in controlled arrival-rate scenarios;
- equal controlled-workload iteration count inside every pair;
- Docker stats timestamped and filtered to the exact k6 process window;
- stats collector joined before summary and manifest creation;
- every per-run manifest remains valid;
- JFR window differs from k6 by no more than 5 seconds;
- no JFR data-loss events;
- application and simulator samples exist inside every measured window;
- suite audit returns `PASS`.

## 2. Experiment taxonomy

### Controlled moderate

```text
25 req/s, 60 s, constant-arrival-rate
```

Purpose: latency distribution, resource efficiency, and stability under a realistic fixed schedule.

### Controlled high

```text
150 req/s, 120 s, constant-arrival-rate
preAllocatedVUs=180, maxVUs=240
```

Purpose: high-concurrency resource efficiency with a lossless schedule. This is **not** maximum throughput.

### Capacity

```text
200 constant VUs, 120 s
```

Purpose: saturation-oriented achieved throughput, latency degradation, and resource behavior. Interpret separately from controlled-rate scenarios.

### Diagnostic scenarios

`slow-payment`, `intermittent-failures`, VisualVM, and INFO-level logging are operational/diagnostic evidence. Do not aggregate them into deterministic performance conclusions.

## 3. Host preparation

1. Reboot or begin from a quiet machine state.
2. Close browsers, IDE indexing, builds, sync clients, and unrelated containers.
3. Connect AC power and keep the same power/performance policy throughout.
4. Do not run VisualVM interactively during the quantitative suite.
5. Confirm no stale containers.
6. Validate environment, code, and Git identity.

```bash
make -C labs/01-loom-vs-reactive-checkout down

docker ps

labs/01-loom-vs-reactive-checkout/scripts/check-environment.sh
./scripts/verify-evidence-tooling.sh
./scripts/verify-all.sh

git status --short
git rev-parse HEAD
```

The worktree must be clean before the formal suite.

## 4. Qualification runs

Before the long suite, execute one isolated run per stack for moderate load. These are qualification artifacts, not final repetitions:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence.sh \
  --implementation mvc-vthreads \
  --scenario moderate \
  --pair 0 \
  --order 1 \
  --run-number 0

labs/01-loom-vs-reactive-checkout/scripts/run-evidence.sh \
  --implementation webflux-reactor \
  --scenario moderate \
  --pair 0 \
  --order 2 \
  --run-number 0
```

Required fields in both `run-summary.json` files:

```text
dropped_iterations = 0
docker_stats_sample_count > 0
simulator_stats_sample_count > 0
abs(jfr_window_overhead_seconds) <= 5
jfr_data_loss_event_count = 0
```

## 5. Canonical controlled-rate suite

```bash
WORKLOAD_SEED=20260718 \
BENCHMARK_LOG_LEVEL=WARN \
make -C labs/01-loom-vs-reactive-checkout evidence-suite \
  SCENARIOS=moderate,high \
  PAIRS=4 \
  COOLDOWN_SECONDS=15
```

This is the official minimum:

```text
2 scenarios × 4 pairs × 2 implementations = 16 isolated runs
```

A six-pair suite may be used when more repetitions are desired, but it does not turn a local experiment into a universal benchmark.

Resume is valid only for the same Git SHA, source fingerprint, runtime/resource configuration fingerprint, scenarios, pair count, and workload seed.

## 6. Capacity suite

Run capacity separately so saturation semantics cannot contaminate controlled-rate interpretation:

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-suite \
  SCENARIOS=capacity \
  PAIRS=4 \
  COOLDOWN_SECONDS=20 \
  WORKLOAD_SEED=20260718
```

## 7. Mandatory automated audit

```bash
SUITE_DIR=/absolute/path/to/the/suite

make -C labs/01-loom-vs-reactive-checkout evidence-audit \
  SUITE_DIR="$SUITE_DIR"

cat "$SUITE_DIR/SUITE_AUDIT.md"
```

Expected status:

```text
PASS
```

Any failed gate invalidates the affected suite. Do not manually edit summaries to make a suite pass.

## 8. Materialize and validate curated evidence

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-docs \
  SUITE_DIR="$SUITE_DIR" \
  UPDATE_ANALYSIS=1

CURATED_DIR="docs/results/evidence/$(basename "$SUITE_DIR")"

make -C labs/01-loom-vs-reactive-checkout evidence-validate \
  CURATED_DIR="$CURATED_DIR"
```

Review:

```text
SUITE_AUDIT.md
COMPARISON.md
FACTUAL_OBSERVATIONS.md
comparison-aggregates.json
comparison.csv
all per-run RUN_SUMMARY.md files
all JFR_METRICS.md files
```

## 9. Separate observability evidence

After quantitative suites, run one diagnostic session per stack with INFO logs and optional VisualVM. Never merge these numbers into quantitative tables.

```bash
BENCHMARK_LOG_LEVEL=INFO \
  labs/01-loom-vs-reactive-checkout/scripts/run-evidence.sh \
  --implementation mvc-vthreads --scenario moderate \
  --pair 900 --order 1 --run-number 1

BENCHMARK_LOG_LEVEL=INFO \
  labs/01-loom-vs-reactive-checkout/scripts/run-evidence.sh \
  --implementation webflux-reactor --scenario moderate \
  --pair 900 --order 2 --run-number 1
```

Use these runs for log readability, stack traces, correlation, debugging, and operational narrative—not for efficiency claims.

## 10. Evidence package for manual analysis

Retain and share:

- raw suite directory or packaged archive;
- curated evidence directory;
- `SUITE_AUDIT.md` and `suite-audit.json`;
- `comparison-aggregates.json` and `comparison.csv`;
- all `run-summary.json` and `JFR_METRICS.md` files;
- exact `git status --short` and `git rev-parse HEAD` output;
- optional VisualVM snapshots/screenshots from separate diagnostic sessions when diagnostic claims are in scope;
- host events that may have disturbed a run.

## 11. Interpretation contract

The final analysis must separate:

```text
observation
inference
alternative explanation
limitation
architectural implication
```

Required wording:

- arrival-rate scenarios describe schedule adherence and efficiency, not capacity;
- capacity results are local saturation evidence, not production SLO predictions;
- the unit of comparison is the complete stack;
- no single metric chooses architecture;
- Loom changes the balance point; it does not remove trade-offs.
