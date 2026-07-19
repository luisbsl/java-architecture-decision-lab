# Evidence Run — `20260718T221113Z-pair01-order02-webflux-reactor-high-run1`

| Field | Value |
|---|---|
| Stack | `Spring WebFlux + Reactor Netty + WebClient` |
| Scenario | `high` |
| Load model | `constant-arrival-rate` (`achieved-arrival-rate`) |
| Pair / order / run | `1 / 2 / 1` |
| Workload seed | `20260718` |
| Git SHA | `14d95f82c6557a7cf5005d80dc2536923aa91ecf` |

## HTTP and measured-window container summary

| Achieved req/s | Configured req/s | Schedule adherence % | Dropped iterations | Avg ms | p95 ms | p99 ms | Error % |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 149.106 | 150.000 | 99.404 | 0.000 | 631.274 | 773.986 | 812.654 | 0.000 |

| Docker samples | App CPU avg / p95 % | App memory baseline / avg / peak MiB | Peak delta MiB | Simulator CPU avg % | Simulator memory peak MiB |
|---:|---:|---:|---:|---:|---:|
| 27 | 37.036 / 68.154 | 181.000 / 294.667 / 315.500 | 134.500 | 23.392 | 227.100 |

## Structured JFR summary

| CPU host-capacity % | CPU one-core % | Equivalent cores | Allocation MiB/s | GC pause ratio % | Platform threads avg / max | VThread pinned | JFR data loss |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.611 | 35.450 | 0.355 | 18.336 | 1.579 | 20.189 / 21 | 0 | 0 |

`JVM CPU host-capacity %` is normalized across all 22 logical CPUs. `CPU one-core %` is directly comparable to Docker's convention where one fully used core is 100%.

## Evidence integrity guardrails

- Docker stats are filtered to the exact `K6_STARTED_NS..K6_ENDED_NS` interval.
- The collector is joined before summary generation and before `manifest.sha256`.
- `dropped_iterations` must be zero for a valid formal run.
- Arrival-rate scenarios report schedule adherence, not maximum server capacity.
- The comparison is between complete application stacks, not an isolated Loom-versus-Reactor microbenchmark.

See `jfr-reports/JFR_METRICS.md` for allocation classes, sampled CPU methods, and concurrency observations.

This run is evidence for the documented environment only; it is not a universal benchmark.
