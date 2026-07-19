# Load-Test Protocol

The load generator creates reproducible HTTP evidence. It does not declare a framework winner.

## Automated run phases

1. clean stop;
2. simulator and one implementation start;
3. readiness verification;
4. environment and effective configuration capture;
5. fixed 20-second warm-up;
6. pre-load Actuator and JVM diagnostics;
7. JFR and Docker sampling start;
8. measured k6 window;
9. post-load snapshots, logs, JFR extraction, and normalized summary;
10. SHA-256 artifact manifest;
11. clean stop.

The complete command is:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence.sh \
  --implementation mvc-vthreads \
  --scenario moderate
```

## Paired execution order

```text
Pair 1: MVC -> WebFlux
Pair 2: WebFlux -> MVC
Pair 3: MVC -> WebFlux
Pair 4: WebFlux -> MVC
```

Automate the complete protocol:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \
  --scenarios moderate,high \
  --pairs 4
```


Execution count:

```text
number of scenarios × pairs × 2 implementations
```

For `moderate,high` and four pairs, the result is 16 runs. Use the suite counter and heartbeat to distinguish normal execution from a stalled process. Interrupted suites can be resumed with `--resume <suite-dir>`; completed normalized runs are skipped.

## Comparability controls

- one checkout implementation runs at a time;
- both use the same simulator settings;
- both use equal Docker CPU and memory limits;
- both use the same JDK family and JFR profile;
- the worktree must be clean;
- every artifact is connected to the Git SHA;
- warm-up, measured duration, and k6 thresholds are explicit;
- execution order alternates across pairs.

## Interpretation guardrail

`intermittent-failures` evaluates resilience and investigation quality. It must not be merged into a deterministic throughput table. `slow-payment` is primarily an operational and timeout scenario.
