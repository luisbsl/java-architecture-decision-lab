# Evidence Run — `20260718T221416Z-pair02-order01-webflux-reactor-high-run2`

| Field | Value |
|---|---|
| Stack | `Spring WebFlux + Reactor Netty + WebClient` |
| Scenario | `high` |
| Load model | `constant-arrival-rate` (`achieved-arrival-rate`) |
| Pair / order / run | `2 / 1 / 2` |
| Workload seed | `20260718` |
| Git SHA | `14d95f82c6557a7cf5005d80dc2536923aa91ecf` |

## HTTP and measured-window container summary

| Achieved req/s | Configured req/s | Schedule adherence % | Dropped iterations | Avg ms | p95 ms | p99 ms | Error % |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 149.081 | 150.000 | 99.387 | 0.000 | 630.743 | 773.302 | 812.180 | 0.000 |

| Docker samples | App CPU avg / p95 % | App memory baseline / avg / peak MiB | Peak delta MiB | Simulator CPU avg % | Simulator memory peak MiB |
|---:|---:|---:|---:|---:|---:|
| 27 | 36.232 / 93.597 | 179.600 / 294.870 / 316.200 | 136.600 | 24.112 | 222.300 |

## Structured JFR summary

| CPU host-capacity % | CPU one-core % | Equivalent cores | Allocation MiB/s | GC pause ratio % | Platform threads avg / max | VThread pinned | JFR data loss |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.620 | 35.631 | 0.356 | 18.439 | 1.570 | 20.189 / 21 | 0 | 0 |

`JVM CPU host-capacity %` is normalized across all 22 logical CPUs. `CPU one-core %` is directly comparable to Docker's convention where one fully used core is 100%.

## Evidence integrity guardrails

- Docker stats are filtered to the exact `K6_STARTED_NS..K6_ENDED_NS` interval.
- The collector is joined before summary generation and before `manifest.sha256`.
- `dropped_iterations` must be zero for a valid formal run.
- Arrival-rate scenarios report schedule adherence, not maximum server capacity.
- The comparison is between complete application stacks, not an isolated Loom-versus-Reactor microbenchmark.

See `jfr-reports/JFR_METRICS.md` for allocation classes, sampled CPU methods, and concurrency observations.

This run is evidence for the documented environment only; it is not a universal benchmark.
