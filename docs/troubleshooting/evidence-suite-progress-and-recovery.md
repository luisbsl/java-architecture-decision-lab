# Evidence Suite Progress, Watchdogs, and Recovery

The complete command is intentionally larger than it first appears:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \
  --scenarios moderate,high \
  --pairs 4
```

It executes:

```text
2 scenarios × 4 pairs × 2 implementations = 16 isolated evidence runs
```

Each run starts fresh containers, performs warm-up, records a measured k6 phase, captures Actuator/JVM/Docker/JFR evidence, renders reports, and tears the environment down. The suite prints an estimate derived from the selected scenarios and run count. Actual elapsed time depends on image cache, storage, CPU policy, Docker resources, and cooldown configuration.

## Progress output

The suite prints:

```text
[PLAN] ... total_runs=12 estimated_minutes≈27
[SUITE 01/12] START ...
[PHASE] ... warm-up ...
[K6] still running elapsed=15s ...
[SUITE 01/12] DONE ...
```

k6 progress animation is not reliable when its output is piped to a file. The explicit heartbeat is therefore the source of truth that the measured phase is still active.

## Bounded JFR report generation

The pipeline keeps the original `recording.jfr`, text views, event counts, and a compressed export of rare virtual-thread failure events. It does not expand every `ThreadPark` or `JavaMonitorEnter` event into verbose JSON. In the previous implementation, a single 4–5 MiB recording could produce a 140+ MiB JSON report, multiplying disk usage and post-processing time across the suite.

## Safety watchdogs

The pipeline now has two watchdog layers:

- a measured-load watchdog inside each evidence run;
- a whole-run watchdog in the paired suite.

Defaults are deliberately larger than the planned workload:

| Scenario | Measured load | Whole-run watchdog |
|---|---:|---:|
| functional | 1 second | 180 seconds |
| moderate | 60 seconds | 300 seconds |
| high | 120 seconds | 420 seconds |
| slow-payment | 60 seconds | 300 seconds |
| intermittent-failures | 60 seconds | 300 seconds |

Override the whole-run watchdog only when the host is known to be unusually slow:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \
  --scenarios moderate,high \
  --pairs 4 \
  --run-timeout-seconds 600
```

A timeout preserves the partial run directory and triggers cleanup. It does not silently continue with invalid evidence.

## Resume an interrupted suite

Completed runs are identified by `run-summary.json`. Resume skips those runs and repeats only missing or incomplete combinations. The suite validates the exact Git SHA, source/protocol fingerprint, and runtime/resource configuration fingerprint; evidence produced with different code, CPU/memory limits, logging, thresholds, warm-up, or scenario overrides is never mixed silently:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \
  --scenarios moderate,high \
  --pairs 4 \
  --resume .artifacts/evidence/<SUITE_ID>-paired-evidence
```

Incomplete directories remain available for diagnosis but are ignored by aggregation unless they contain a valid normalized summary.

After changing any application, load-test, Compose, profiling, or evidence script, start a new formal suite. `--resume` is only for interruptions under the same source revision, protocol fingerprint, and runtime/resource configuration fingerprint.

## What to inspect after an interruption

Inside the incomplete run directory, inspect:

```text
run.env
load/k6-console.txt
warmup-console.txt
docker-stats-console.txt
compose-logs.txt
jfr-stop-on-exit.txt
compose-down.txt
RUN_FAILED.md
```

A run is complete only when it contains:

```text
run-summary.json
RUN_SUMMARY.md
manifest.sha256
```

Do not treat repeated pair execution as a loop. Confirm the `[SUITE current/total]` counter first.
