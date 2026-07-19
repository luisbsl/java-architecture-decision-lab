# Evidence Run — `20260718T215811Z-pair02-order02-mvc-vthreads-moderate-run2`

| Field | Value |
|---|---|
| Stack | `Spring MVC + Tomcat + Virtual Threads + JDK HttpClient` |
| Scenario | `moderate` |
| Load model | `constant-arrival-rate` (`achieved-arrival-rate`) |
| Pair / order / run | `2 / 2 / 2` |
| Workload seed | `20260718` |
| Git SHA | `14d95f82c6557a7cf5005d80dc2536923aa91ecf` |

## HTTP and measured-window container summary

| Achieved req/s | Configured req/s | Schedule adherence % | Dropped iterations | Avg ms | p95 ms | p99 ms | Error % |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 24.695 | 25.000 | 98.781 | 0.000 | 633.682 | 771.698 | 814.826 | 0.000 |

| Docker samples | App CPU avg / p95 % | App memory baseline / avg / peak MiB | Peak delta MiB | Simulator CPU avg % | Simulator memory peak MiB |
|---:|---:|---:|---:|---:|---:|
| 14 | 28.299 / 40.909 | 179.300 / 231.521 / 249.000 | 69.700 | 15.181 | 175.900 |

## Structured JFR summary

| CPU host-capacity % | CPU one-core % | Equivalent cores | Allocation MiB/s | GC pause ratio % | Platform threads avg / max | VThread pinned | JFR data loss |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.258 | 27.671 | 0.277 | 7.528 | 0.130 | 26.065 / 27 | 0 | 0 |

`JVM CPU host-capacity %` is normalized across all 22 logical CPUs. `CPU one-core %` is directly comparable to Docker's convention where one fully used core is 100%.

## Evidence integrity guardrails

- Docker stats are filtered to the exact `K6_STARTED_NS..K6_ENDED_NS` interval.
- The collector is joined before summary generation and before `manifest.sha256`.
- `dropped_iterations` must be zero for a valid formal run.
- Arrival-rate scenarios report schedule adherence, not maximum server capacity.
- The comparison is between complete application stacks, not an isolated Loom-versus-Reactor microbenchmark.

See `jfr-reports/JFR_METRICS.md` for allocation classes, sampled CPU methods, and concurrency observations.

This run is evidence for the documented environment only; it is not a universal benchmark.
