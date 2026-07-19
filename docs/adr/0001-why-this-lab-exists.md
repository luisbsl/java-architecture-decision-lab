# ADR-0001 — Why This Lab Exists

## Status

Accepted

## Context

Architectural discussions about Java concurrency often collapse into framework preference, isolated throughput numbers, or universal conclusions drawn from local benchmarks.

The public engineering strategy for this repository requires a stronger evidence layer: executable code, reproducible conditions, profiling, operational signals, and explicit limitations.

## Decision

Create a long-lived Java Architecture Decision Lab whose experiments are organized around architectural questions rather than framework tutorials.

The first experiment models the same Order Checkout Flow with Spring MVC + Virtual Threads and Spring WebFlux + Reactor.

## Rationale

A shared domain makes differences in concurrency model, programming style, debugging, observability, and operational complexity easier to inspect without changing the business problem.

Incremental pull requests preserve the reasoning and make each milestone reviewable.

## Consequences

### What becomes easier

- connecting architectural claims to executable evidence;
- reviewing assumptions and non-goals;
- reproducing experiments;
- comparing code and runtime behavior under the same workload;
- extending the repository with future decision labs.

### What becomes harder

- experiments require disciplined environment documentation;
- results must be interpreted rather than promoted as universal truth;
- keeping implementations functionally equivalent requires continuous review.

## Alternatives Considered

### A single tutorial repository

Rejected because it would optimize for teaching framework APIs rather than exposing trade-offs.

### Separate repositories for each implementation

Rejected for the first lab because comparison, shared documentation, and coordinated test conditions would become harder.

## What This Decision Does Not Mean

- The repository is not a production reference architecture.
- The repository does not declare a universal framework winner.
- Local profiling does not predict every production environment.
