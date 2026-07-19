# Protocol Lessons Learned from a Discarded Diagnostic Suite

> **Verdict:** A previous 12-run diagnostic suite completed successfully at the process level, but its quantitative results were rejected because evidence integrity and experimental-design gates were not strong enough.

This document preserves the engineering lessons that shaped the final publication-grade protocol. The rejected numbers are hypotheses only and must not be presented as final results.

## 1. Historical diagnostic scope

- Scenarios: `moderate`, `high`;
- repetitions: 3 pairs per scenario;
- total: 12 isolated application runs;
- runtime: Java 21, Spring Boot, Docker Compose, k6, and JFR;
- sources reviewed: raw artifacts, k6 summaries, manifests, Docker stats, JFR reports, runner scripts, simulator code, and application logging.

## 2. Why the suite was rejected

| Dimension | Diagnostic outcome | Final protocol response |
|---|---|---|
| Functional correctness | Requests and checks completed | Kept as a prerequisite, not enough for publication |
| Pair completion | 12/12 runs completed | Even pair count is now mandatory for balanced order |
| Controlled load | High scenario used a programmed ramp | Moderate/high now use fixed arrival rates |
| Dropped iterations | High runs dropped iterations | Any dropped iteration invalidates controlled-rate evidence |
| Docker CPU/memory | Collector outlived the measured run | Collector is lifecycle-controlled and joined before manifests |
| JFR window | Recording included an idle tail | JFR is stopped at the exact k6 boundary |
| Workload pairing | Random delays differed across stacks | Workload identity and simulator seed are deterministic |
| Logging | Success logs distorted allocation/CPU | Quantitative runs use WARN; INFO is diagnostic-only |
| Causal scope | More than concurrency model differed | Results are framed as complete-stack comparisons |

## 3. Docker Stats lifecycle defect

The original collector was launched through a shell pipeline. Stopping the parent process did not guarantee that all descendants stopped. Some collectors continued appending after their run finished, contaminating later runs and invalidating manifests.

Final design:

- one dedicated collector process;
- explicit stop file;
- bounded `docker stats --no-stream` samples;
- process join before summary generation;
- timestamp filtering to the exact measured window;
- SHA-256 validation after all writers stop.

## 4. Measured-window defect

The original heartbeat implementation polled k6 in long sleep intervals. When k6 finished during a sleep, JFR and Docker collection remained active until the next poll.

Final design:

- k6 runs as the directly waited child process;
- heartbeat runs independently;
- start/end timestamps are captured around the k6 process;
- JFR is stopped immediately after k6 exits;
- audit rejects excessive JFR/k6 window drift.

## 5. Load-model defect

A ramping arrival-rate profile was initially described as “high throughput.” Near-equal achieved request rates mainly showed adherence to the programmed schedule, not server capacity.

Final taxonomy:

```text
moderate/high = controlled-rate latency and resource efficiency
capacity      = separate saturation-oriented experiment
```

## 6. Workload-pairing defect

Independent random delays meant MVC and WebFlux did not receive the same synthetic workload inside a pair.

Final design derives each simulated delay/failure decision from:

```text
workload seed + scenario + pair + logical iteration + simulated service
```

The same correlation/workload identity is propagated through both stacks to the simulator.

## 7. Logging confounder

Per-request structured INFO logs generated substantial encoding and allocation work. That is valuable observability evidence, but it is a confounder for resource-efficiency measurements.

Final policy:

- quantitative suite: application log level `WARN`;
- observability/operability session: `INFO`;
- never merge diagnostic logging numbers into quantitative tables.

## 8. Interpretation lesson

The lab compares:

```text
Spring MVC + Tomcat + Virtual Threads + JDK HttpClient
versus
Spring WebFlux + Reactor Netty + WebClient
```

It does not isolate one language/runtime feature from the rest of each stack.

The final analysis therefore reports multiple dimensions and avoids statements such as:

- “Loom always wins”;
- “WebFlux is obsolete”;
- “local throughput predicts production”;
- “one metric decides architecture.”

## 9. Permanent rule

When an evidence gate fails:

1. preserve the failed suite for diagnosis;
2. fix the code or protocol;
3. commit the fix;
4. start a new suite from the new clean Git SHA;
5. never repair evidence by hand.
