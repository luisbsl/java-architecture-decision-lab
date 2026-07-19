# ADR-0003 — Profiling Is Not a Winner Machine

## Status

Accepted

## Context

A profiler can reveal behavior, but metrics can be selectively presented to support a predetermined conclusion. Throughput alone also hides tail latency, resource pressure, debugging cost, and operational complexity.

## Decision

Use profiling to explain behavior across multiple dimensions rather than to declare a universal winner.

The analysis will include, when applicable:

- requests per second;
- average, p95, and p99 latency;
- error and timeout rate;
- CPU and allocation rate;
- heap and GC behavior;
- platform and virtual thread observations;
- stack traces and debugging experience;
- code complexity and cognitive load;
- observability and operational clarity.

Every published result must state the environment, workload, configuration, and limitations.

## Rationale

Architecture is a trade-off. A responsible experiment should make behavior inspectable while protecting readers from conclusions the test cannot support.

## Consequences

Reports may be less sensational, but they will be more credible and reusable.

## Alternatives Considered

- Rank implementations by a single score: rejected as misleading.
- Publish only code: rejected because runtime claims would remain unsupported.
- Publish only profiler screenshots: rejected because reproduction and interpretation would be weak.

## What This Decision Does Not Mean

- Quantitative results are unimportant.
- All approaches are equivalent.
- No decision can be recommended for a clearly described context.
