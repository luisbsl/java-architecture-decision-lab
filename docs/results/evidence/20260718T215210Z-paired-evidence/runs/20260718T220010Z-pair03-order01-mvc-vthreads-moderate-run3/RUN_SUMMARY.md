# Evidence Run — `20260718T220010Z-pair03-order01-mvc-vthreads-moderate-run3`

| Field | Value |
|---|---|
| Stack | `Spring MVC + Tomcat + Virtual Threads + JDK HttpClient` |
| Scenario | `moderate` |
| Load model | `constant-arrival-rate` (`achieved-arrival-rate`) |
| Pair / order / run | `3 / 1 / 3` |
| Workload seed | `20260718` |
| Git SHA | `14d95f82c6557a7cf5005d80dc2536923aa91ecf` |

## HTTP and measured-window container summary

| Achieved req/s | Configured req/s | Schedule adherence % | Dropped iterations | Avg ms | p95 ms | p99 ms | Error % |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 24.742 | 25.000 | 98.968 | 0.000 | 636.167 | 775.437 | 810.274 | 0.000 |

| Docker samples | App CPU avg / p95 % | App memory baseline / avg / peak MiB | Peak delta MiB | Simulator CPU avg % | Simulator memory peak MiB |
|---:|---:|---:|---:|---:|---:|
| 13 | 28.079 / 44.606 | 177.600 / 239.846 / 255.400 | 77.800 | 14.049 | 173.400 |

## Structured JFR summary

| CPU host-capacity % | CPU one-core % | Equivalent cores | Allocation MiB/s | GC pause ratio % | Platform threads avg / max | VThread pinned | JFR data loss |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.259 | 27.695 | 0.277 | 7.449 | 0.138 | 26.855 / 27 | 0 | 0 |

`JVM CPU host-capacity %` is normalized across all 22 logical CPUs. `CPU one-core %` is directly comparable to Docker's convention where one fully used core is 100%.

## Evidence integrity guardrails

- Docker stats are filtered to the exact `K6_STARTED_NS..K6_ENDED_NS` interval.
- The collector is joined before summary generation and before `manifest.sha256`.
- `dropped_iterations` must be zero for a valid formal run.
- Arrival-rate scenarios report schedule adherence, not maximum server capacity.
- The comparison is between complete application stacks, not an isolated Loom-versus-Reactor microbenchmark.

See `jfr-reports/JFR_METRICS.md` for allocation classes, sampled CPU methods, and concurrency observations.

This run is evidence for the documented environment only; it is not a universal benchmark.
