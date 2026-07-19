# Master Runbook — Java Architecture Decision Lab

> **This is not a definitive benchmark.**
>
> This is the single operational source of truth for building, validating, executing, measuring, documenting, and releasing the Loom vs Reactive Checkout lab.

## 0. Final objective

A successful execution ends with all of the following:

- Maven reactor verified on Java 21;
- all three services built and started with Docker Compose;
- functional, checkout, observability, and correlation-ID smoke tests passing;
- one qualification run for each implementation;
- one balanced formal suite with four pairs per scenario;
- suite audit status `PASS`;
- curated Markdown, JSON, and CSV evidence generated from raw artifacts;
- manual architectural interpretation completed without altering generated evidence;
- repository published from one clean `main` history;
- release tag and optional raw evidence archive published.

## 1. Extract the delivery

```bash
unzip java-architecture-decision-lab.zip
cd java-architecture-decision-lab
```

When the checksum file is delivered beside the archive:

```bash
sha256sum -c java-architecture-decision-lab.zip.sha256
```

The delivery intentionally contains no `.git` directory and no historical branch stack.

## 2. Install and validate prerequisites

Required for build and runtime verification:

```text
JDK 21
Docker Engine
Docker Compose v2
Bash
Make
curl
unzip
Git
```

Required for formal evidence:

```text
k6
python3
jcmd
jfr
GNU timeout
sha256sum
```

Optional for interactive profiling:

```text
VisualVM
JDK Mission Control
GitHub CLI (gh)
```

Run the environment preflight:

```bash
labs/01-loom-vs-reactive-checkout/scripts/check-environment.sh
```

Do not continue while the script reports errors. Repository commands never retry Docker with `sudo`; correct the daemon or socket permissions instead.

## 3. Create one clean Git history

Formal evidence requires one immutable Git SHA and a clean worktree.

```bash
git init -b main
git add .
git commit -m "feat: publish complete Java architecture decision lab"

git status --short
git rev-parse HEAD
```

Expected:

- `git status --short` prints nothing;
- `git rev-parse HEAD` prints one commit SHA.

## 4. Verify evidence tooling before the application build

```bash
./scripts/verify-evidence-tooling.sh
```

This command validates:

- Bash syntax for evidence scripts;
- non-mutating Python syntax validation and unit tests;
- the standalone JFR metrics extractor;
- the custom JFR profile;
- the evidence Compose override when Docker is available.

Expected final line:

```text
[OK] Evidence tooling verification passed.
```

The command is idempotent: it does not generate Python bytecode inside the repository and may be executed repeatedly before `verify-all.sh`. Ignored local caches left by older copies do not change the source-consistency result.

## 5. Run the canonical release verification

```bash
./scripts/verify-all.sh
```

This command is the release gate. It:

1. validates evidence tooling;
2. runs `./mvnw clean verify`;
3. validates Docker Compose;
4. builds and starts all three services;
5. waits for readiness;
6. runs simulator, checkout, observability, and correlation-ID smoke tests;
7. always removes containers.

Expected final line:

```text
[OK] Full project verification passed.
```

A first execution needs external access to Maven Central and the configured container registries.

## 6. Optional manual runtime inspection

Start the entire lab:

```bash
make -C labs/01-loom-vs-reactive-checkout up
```

Inspect status:

```bash
docker compose \
  -f labs/01-loom-vs-reactive-checkout/docker-compose.yml \
  ps
```

Run every smoke test:

```bash
make -C labs/01-loom-vs-reactive-checkout smoke
```

Useful endpoints:

```text
MVC + Virtual Threads: http://localhost:8081
WebFlux + Reactor:      http://localhost:8082
Simulator:              http://localhost:8083
```

Stop and remove the lab:

```bash
make -C labs/01-loom-vs-reactive-checkout down
```

## 7. Prepare the benchmark host

Before quantitative evidence:

1. reboot or begin from a quiet machine state;
2. use AC power and one stable power/performance policy;
3. close IDE indexing, browsers, sync clients, builds, and unrelated containers;
4. do not run VisualVM during the quantitative suite;
5. confirm no stale lab containers;
6. confirm the worktree is clean.

```bash
make -C labs/01-loom-vs-reactive-checkout down

docker ps

git status --short
git rev-parse HEAD
```

Review the formal gates in [`BENCHMARK_PROTOCOL.md`](BENCHMARK_PROTOCOL.md).

## 8. Execute the two qualification runs

Qualification runs verify the complete evidence path before the long suite. They are not final repetitions.

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

For each generated `run-summary.json`, confirm:

```text
dropped_iterations = 0
docker_stats_sample_count > 0
simulator_stats_sample_count > 0
abs(jfr_window_overhead_seconds) <= 5
jfr_data_loss_event_count = 0
```

Do not begin the formal suite if either qualification run fails.

## 9. Execute the canonical formal suite

The official minimum is **four balanced pairs per scenario**. An even pair count is mandatory so MVC-first and WebFlux-first order is balanced.

```bash
WORKLOAD_SEED=20260718 \
BENCHMARK_LOG_LEVEL=WARN \
make -C labs/01-loom-vs-reactive-checkout evidence-suite \
  SCENARIOS=moderate,high \
  PAIRS=4 \
  COOLDOWN_SECONDS=15
```

This schedules:

```text
2 scenarios × 4 pairs × 2 implementations = 16 isolated runs
```

The runner prints:

- suite ID;
- protocol version and source fingerprint;
- runtime/resource configuration fingerprint;
- exact Git SHA;
- total run count;
- an estimated duration for the current host;
- `[SUITE current/total]` progress;
- k6 heartbeat output;
- the exact resume command after interruption.

Do not interpret `moderate` or `high` as maximum throughput. Both are controlled arrival-rate scenarios.

## 10. Resume an interrupted suite

Use the exact command printed by the runner, or:

```bash
WORKLOAD_SEED=20260718 \
BENCHMARK_LOG_LEVEL=WARN \
make -C labs/01-loom-vs-reactive-checkout evidence-suite \
  SCENARIOS=moderate,high \
  PAIRS=4 \
  COOLDOWN_SECONDS=15 \
  RESUME=.artifacts/evidence/<SUITE_ID>-paired-evidence
```

Resume is accepted only when all identities still match:

- Git SHA;
- protocol version;
- protocol fingerprint;
- runtime/resource configuration fingerprint (CPU, memory, logging, warm-up, thresholds, and scenario overrides);
- scenarios;
- pair count;
- workload seed.

Completed normalized runs are skipped. Never copy a previous suite into a new protocol revision.

## 11. Audit the completed raw suite

The suite runner audits automatically. Re-run the audit explicitly before curation:

```bash
SUITE_DIR="$(find "$PWD/.artifacts/evidence" -mindepth 1 -maxdepth 1 \
  -type d -name '*-paired-evidence' | sort | tail -n 1)"

make -C labs/01-loom-vs-reactive-checkout evidence-audit \
  SUITE_DIR="$SUITE_DIR"

cat "$SUITE_DIR/SUITE_AUDIT.md"
```

`SUITE_DIR` is deliberately absolute. `make -C` changes the working directory before invoking the target; passing a repository-relative path without normalization would point the auditor at the lab directory instead of the repository root.

Required status:

```text
PASS
```

Any failed gate invalidates the suite. Never edit raw summaries or manifests to force a pass.

## 12. Generate curated evidence and analysis tables

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-docs \
  SUITE_DIR="$SUITE_DIR" \
  UPDATE_ANALYSIS=1
```

This command:

- preserves the raw suite as immutable evidence;
- generates linked Markdown, JSON, and CSV artifacts;
- copies only small, sanitized evidence into `docs/results/evidence/`;
- updates only the generated evidence block in the comparative analysis;
- validates the curated SHA-256 manifest.

Validate again explicitly:

```bash
CURATED_DIR="$PWD/docs/results/evidence/$(basename "$SUITE_DIR")"

make -C labs/01-loom-vs-reactive-checkout evidence-validate \
  CURATED_DIR="$CURATED_DIR"
```

Review at minimum:

```text
$SUITE_DIR/SUITE_AUDIT.md
$SUITE_DIR/COMPARISON.md
$SUITE_DIR/comparison-aggregates.json
$SUITE_DIR/comparison.csv
$CURATED_DIR/FACTUAL_OBSERVATIONS.md
docs/results/01-loom-vs-reactive-analysis.md
```

## 13. Complete the manual engineering analysis

Only the generated evidence block is automated. Complete these sections manually in `docs/results/01-loom-vs-reactive-analysis.md`:

- hypotheses written before measurement;
- factual observations;
- evidence supporting each observation;
- inferences;
- alternative explanations;
- limitations;
- architectural implications;
- when MVC + Virtual Threads is more appropriate;
- when WebFlux/Reactor remains more appropriate.

Use this separation consistently:

```text
observation → inference → alternative explanation → limitation → implication
```

Do not publish a universal winner. The compared units are complete stacks:

```text
Spring MVC + Tomcat + Virtual Threads + JDK HttpClient
versus
Spring WebFlux + Reactor Netty + WebClient
```

## 14. Optional separate diagnostic/operability evidence

Interactive profiling is a diagnostic session and must not be merged into quantitative tables. It is optional for the v1.0.0 quantitative release because the canonical numeric evidence already comes from structured JSON/CSV/JFR artifacts. Complete this section only before making measured debugging or operator-experience claims.

MVC session:

```bash
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh start mvc-vthreads
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh load moderate
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh stop
```

WebFlux session:

```bash
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh start webflux-reactor
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh load moderate
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh stop
```

Follow the exact capture checklist in:

- [`../profiling/visualvm-setup.md`](../profiling/visualvm-setup.md)
- [`../profiling/VISUALVM_CAPTURE_CHECKLIST.md`](../profiling/VISUALVM_CAPTURE_CHECKLIST.md)

For observability-rich logs, run separate sessions with `BENCHMARK_LOG_LEVEL=INFO`. Do not merge their resource numbers with the `WARN` quantitative suite.

## 15. Optionally package sanitized raw evidence

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-package \
  SUITE_DIR="$SUITE_DIR"
```

Generated beside the suite:

```text
<SUITE_ID>-paired-evidence.tar.gz
<SUITE_ID>-paired-evidence.tar.gz.sha256
```

Do not commit raw `.jfr`, `.hprof`, unsanitized logs, or full k6 point streams. Publish large artifacts as release assets only after validating the portable checksum and reviewing the archive for local paths, host identifiers, and secrets. The raw archive is optional; curated evidence is sufficient for the source repository release.

## 16. Run the final repository gate

After documentation is complete:

```bash
./scripts/verify-evidence-tooling.sh
./scripts/verify-all.sh

git diff --check
git status --short
```

Review the diff, then commit:

```bash
git add .
git commit -m "docs(results): publish balanced Loom vs Reactive evidence"
```

## 17. Publish to GitHub

Create the public repository from the current clean `main` branch:

```bash
gh repo create java-architecture-decision-lab \
  --public \
  --source=. \
  --remote=origin \
  --push
```

For an existing empty repository:

```bash
git remote add origin git@github.com:luisbsl/java-architecture-decision-lab.git
git push -u origin main
```

After CI is green:

- protect `main`;
- require the `Maven and Docker verification` check;
- block force pushes;
- enable Dependabot alerts;
- require pull requests for later changes.

## 18. Create the first release

```bash
git tag -a v1.0.0 -m "Complete Java architecture decision lab"
git push origin v1.0.0

gh release create v1.0.0 \
  --title "Java Architecture Decision Lab v1.0.0" \
  --notes "Complete MVC + Virtual Threads and WebFlux/Reactor lab with observability, balanced paired evidence, JFR reports, VisualVM workflow, load testing, and publication-grade integrity gates."
```

Upload raw evidence after the release exists:

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-release \
  SUITE_DIR="$SUITE_DIR" \
  RELEASE_TAG=v1.0.0
```

## 19. Final acceptance checklist

The release is complete only when every item is true:

- [ ] Java 21 selected for `java` and `javac`.
- [ ] Docker daemon reachable without repository-level `sudo` workarounds.
- [ ] `./scripts/verify-evidence-tooling.sh` passes.
- [ ] `./scripts/verify-all.sh` passes.
- [ ] Git worktree is clean before formal measurement.
- [ ] Qualification runs pass all integrity fields.
- [ ] Formal suite uses four balanced pairs and zero dropped iterations.
- [ ] `SUITE_AUDIT.md` reports `PASS`.
- [ ] Curated manifest validates.
- [ ] Generated evidence is not manually edited.
- [ ] Manual interpretation separates facts from inference.
- [ ] Optional VisualVM evidence, when present, is kept separate from quantitative results.
- [ ] CI is green on the exact release commit.
- [ ] Tag `v1.0.0` points to the validated commit.
- [ ] Any published raw evidence is sanitized and attached to the release, not committed.

## 20. Recovery rule

When a gate fails, preserve the failed suite for diagnosis, fix the code or protocol, commit the fix, and start a new suite from the new clean Git SHA. Never repair evidence by hand.


## Finalize a fully measured suite after a post-processing failure

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-finalize SUITE_DIR="$SUITE_DIR"
```
