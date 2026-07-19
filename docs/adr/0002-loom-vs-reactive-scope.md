# ADR-0002 — Loom vs Reactive Scope

## Status

Accepted

## Context

Virtual Threads and reactive programming address overlapping but not identical concerns. A comparison without a controlled scope would invite misleading conclusions.

## Decision

Limit the first lab to an I/O-bound request/response Order Checkout Flow with simulated downstream services.

Compare:

- Spring MVC + Virtual Threads;
- Spring WebFlux + Reactor.

Keep the business flow equivalent:

1. validate order;
2. fetch customer;
3. check inventory;
4. authorize payment;
5. persist the order with controlled delay;
6. publish `OrderConfirmed` with controlled delay;
7. return the result.

## Rationale

This workload is intentionally close to common enterprise integration flows while remaining small enough to understand, run locally, profile, and evolve publicly.

## Consequences

The lab can discuss concurrency, code structure, latency distribution, runtime behavior, and operational clarity. It cannot generalize to every streaming, CPU-bound, or event-processing workload.

## Alternatives Considered

- CPU-bound computation: rejected because it would not represent the primary Virtual Thread value proposition.
- Infinite streaming: rejected because it would favor a different problem model.
- Real payment and inventory services: rejected because reproducibility and safety would suffer.

## What This Decision Does Not Mean

- WebFlux is being evaluated only as a faster HTTP stack.
- Virtual Threads guarantee lower latency.
- Reactive programming is unnecessary for streaming, backpressure, or existing reactive ecosystems.
