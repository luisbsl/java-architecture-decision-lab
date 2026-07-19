# Lab 01 — Loom vs Reactive Checkout

This laboratory compares the same enterprise-style I/O-bound checkout flow implemented with:

- Spring MVC + Java 21 Virtual Threads;
- Spring WebFlux + Reactor.

Both implementations, observability instrumentation, load scenarios, profiling scripts, and the comparative-analysis template are included in this release.

> **This is not a definitive benchmark.**

## Functional flow

```text
POST /orders/checkout
  -> customer lookup
  -> inventory check
  -> payment authorization
  -> controlled persistence delay
  -> controlled event-publication delay
  -> confirmed response
```

## Commands

From the repository root:

```bash
./scripts/verify-all.sh
```

From this directory:

```bash
make verify
make up
make smoke
make down
```

Individual services:

```bash
make up-simulator
make up-mvc
make up-webflux
```

Individual smoke tests:

```bash
make smoke-simulator
make smoke-mvc
make smoke-webflux
make smoke-observability
```

## Configurable downstream behavior

```text
CUSTOMER_MIN_DELAY=80ms
CUSTOMER_MAX_DELAY=150ms
CUSTOMER_FAILURE_RATE=0.00
INVENTORY_MIN_DELAY=100ms
INVENTORY_MAX_DELAY=250ms
INVENTORY_FAILURE_RATE=0.00
PAYMENT_MIN_DELAY=150ms
PAYMENT_MAX_DELAY=400ms
PAYMENT_FAILURE_RATE=0.00
```

A failure rate must be between `0.0` and `1.0`.

## Measurement discipline

Comparative values should only be published together with:

- exact Git SHA;
- environment manifest;
- effective Docker Compose configuration;
- raw k6 output;
- repetition count and run order;
- explicit limitations.

## Evidence documentation automation

After a complete suite, generate all curated tables and update the managed analysis block:

```bash
make evidence-docs UPDATE_ANALYSIS=1
```

The workflow derives documentation from k6, Docker Stats, and bounded JFR artifacts. VisualVM or JDK Mission Control can reopen the raw `.jfr` recordings for offline interpretation, but published numeric tables are generated from structured files rather than copied from screenshots.

See [`../../docs/profiling/AUTOMATED_DOCUMENTATION_WORKFLOW.md`](../../docs/profiling/AUTOMATED_DOCUMENTATION_WORKFLOW.md).
