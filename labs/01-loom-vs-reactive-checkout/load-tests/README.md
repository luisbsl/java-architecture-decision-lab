# k6 Load Scenarios

One parameterized script is used against both checkout implementations. The request body, checks, metric names, and scenario semantics remain the same; only `BASE_URL` and the `implementation` tag change.

## Prerequisite

```bash
k6 version
```

## Functional run

```bash
IMPLEMENTATION=mvc-vthreads SCENARIO=functional \
  ./labs/01-loom-vs-reactive-checkout/scripts/run-load-test.sh

IMPLEMENTATION=webflux-reactor SCENARIO=functional \
  ./labs/01-loom-vs-reactive-checkout/scripts/run-load-test.sh
```

## Scenario matrix

| Scenario | Intent | Simulator configuration |
|---|---|---|
| `functional` | Contract and correlation | Fixed or default delays, zero failures |
| `moderate` | Stable I/O-bound load below saturation | Fixed delays, zero failures |
| `high` | Approach saturation progressively | Fixed delays, zero failures |
| `slow-payment` | Timeout and operational investigation | Fixed high payment delay, zero failures |
| `intermittent-failures` | Error classification and diagnosis | Fixed delays, controlled non-zero payment failures |

For clean throughput comparisons, use deterministic delays:

```bash
CUSTOMER_MIN_DELAY=100ms CUSTOMER_MAX_DELAY=100ms \
INVENTORY_MIN_DELAY=150ms INVENTORY_MAX_DELAY=150ms \
PAYMENT_MIN_DELAY=250ms PAYMENT_MAX_DELAY=250ms \
PAYMENT_FAILURE_RATE=0.00 \
docker compose up --build -d
```

## Formal measured run

```bash
MEASURED_RUN=true \
IMPLEMENTATION=mvc-vthreads \
SCENARIO=moderate \
RUN_ID=20260715-180000Z-mvc-vthreads-moderate-run1 \
./labs/01-loom-vs-reactive-checkout/scripts/run-load-test.sh
```

A formal run refuses a dirty worktree. Raw JSON points and summaries are stored under `.artifacts/` and must not be committed.

## Fairness rules

- warm up separately before the measured window;
- use the same script, payload, rate, duration, and timeout;
- keep JDK, host, container limits, and simulator settings constant;
- execute at least four paired runs;
- alternate order: MVC -> WebFlux, WebFlux -> MVC, MVC -> WebFlux;
- never publish only the best run;
- keep intermittent failures out of clean throughput conclusions.

## What these scenarios do not prove

A local k6 result is not production capacity, and RPS is not the only architectural criterion.
