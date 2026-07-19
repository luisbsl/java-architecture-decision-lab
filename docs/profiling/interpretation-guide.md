# Profiling Interpretation Guide

## First establish the workload

- Was the run actually I/O-bound?
- Were fixed downstream delays and zero failures used for clean comparison?
- Did the load generator saturate?
- Did connection or downstream limits become the bottleneck?
- Was warm-up complete before the measured window?

## Quantitative questions

- Are RPS, average, p95, and p99 stable across paired repetitions?
- Were errors and timeouts counted identically?
- What changed in CPU, heap, allocation, and GC?
- What changed in platform-thread behavior?
- Were Virtual Thread pinning events observed, and under which code path?
- Did profiler attachment change the result materially?

## Qualitative questions

- Which stack trace made a degraded payment dependency easier to reconstruct?
- Could the correlation ID be followed across checkout and simulator logs?
- Which implementation made timeout and cancellation behavior clearer?
- What code or runtime knowledge was required to explain the failure?
- What became simpler, and what became harder?

## Separate statement types

```text
Observation: what a captured artifact directly shows.
Inference: the explanation supported by one or more observations.
Limitation: why the inference may not transfer.
Decision implication: how the evidence affects this workload's trade-off.
```

Profiling is evidence. Interpretation remains an engineering responsibility.
