# Evidence Comparison

> **This is not a definitive benchmark.** Values are median `[min, max]` plus coefficient of variation across isolated runs.

- Suite: `20260718T215210Z-paired-evidence`
- Status: **complete**
- Completed runs: **16** / **16**
- Protocol version: `4`
- Protocol fingerprint: `a4fed544463e5208363a99e9d866875205ec63bff916440742f817b4b417fe63`
- Git SHA: `14d95f82c6557a7cf5005d80dc2536923aa91ecf`
- Workload seed: `20260718`
- Arrival-rate scenarios measure schedule adherence at a controlled rate; only the capacity scenario is interpreted as saturation throughput.
- The compared units are full stacks: MVC/Tomcat/JDK HttpClient versus WebFlux/Reactor Netty/WebClient.

## HTTP and measured-window container evidence

| Stack | Scenario | Runs | Achieved req/s | Schedule adherence % | Dropped | Avg ms | p95 ms | p99 ms | App CPU avg % | Memory peak delta MiB | Simulator CPU avg % |
|---|---|---:|---|---|---|---|---|---|---|---|---|
| Spring MVC + Tomcat + Virtual Threads + JDK HttpClient | high | 4 | 149.105 [149.079, 149.109] CV=0.0% | 99.404 [99.386, 99.406] CV=0.0% | 0 [0, 0] CV=0.0% | 632.141 [630.045, 632.849] CV=0.2% | 776.450 [775.119, 777.732] CV=0.2% | 818.704 [816.911, 827.533] CV=0.5% | 54.913 [54.063, 56.071] CV=1.6% | 241.950 [239.300, 250.200] CV=1.7% | 24.929 [23.659, 26.514] CV=4.1% |
| Spring MVC + Tomcat + Virtual Threads + JDK HttpClient | moderate | 4 | 24.723 [24.695, 24.762] CV=0.1% | 98.893 [98.781, 99.049] CV=0.1% | 0 [0, 0] CV=0.0% | 634.432 [630.516, 636.167] CV=0.3% | 775.275 [771.698, 778.337] CV=0.3% | 811.674 [810.274, 814.826] CV=0.2% | 28.189 [27.600, 28.459] CV=1.2% | 74.400 [69.700, 90.200] CV=10.5% | 14.004 [12.978, 15.181] CV=5.6% |
| Spring WebFlux + Reactor Netty + WebClient | high | 4 | 149.102 [149.081, 149.109] CV=0.0% | 99.401 [99.387, 99.406] CV=0.0% | 0 [0, 0] CV=0.0% | 630.920 [629.565, 631.274] CV=0.1% | 773.771 [773.302, 774.169] CV=0.0% | 813.505 [812.180, 814.926] CV=0.1% | 36.634 [33.437, 37.471] CV=4.4% | 134.900 [130.300, 136.600] CV=1.8% | 23.765 [23.392, 24.112] CV=1.1% |
| Spring WebFlux + Reactor Netty + WebClient | moderate | 4 | 24.724 [24.679, 24.780] CV=0.2% | 98.897 [98.716, 99.119] CV=0.2% | 0 [0, 0] CV=0.0% | 633.582 [629.826, 635.484] CV=0.3% | 774.422 [770.492, 777.201] CV=0.3% | 810.702 [808.467, 816.969] CV=0.4% | 21.015 [20.754, 22.676] CV=3.6% | 66.900 [45.300, 82.300] CV=23.6% | 13.010 [12.048, 13.966] CV=5.3% |

## Structured JFR evidence

| Stack | Scenario | CPU one-core % | Equivalent cores | Allocation MiB/s | GC pause ratio % | Platform threads avg / max | VThread pinned | JFR data loss |
|---|---|---|---|---|---|---|---:|---:|
| Spring MVC + Tomcat + Virtual Threads + JDK HttpClient | high | 55.853 [54.761, 64.931] CV=7.1% | 0.559 [0.548, 0.649] CV=7.1% | 34.911 [34.800, 35.050] CV=0.3% | 1.508 [1.438, 1.539] CV=2.5% | 49.542 [49.090, 51.164] CV=1.6% / 52.000 [51.000, 54.000] CV=2.1% | 0 [0, 0] CV=0.0% | 0 [0, 0] CV=0.0% |
| Spring MVC + Tomcat + Virtual Threads + JDK HttpClient | moderate | 27.767 [27.671, 28.655] CV=1.4% | 0.278 [0.277, 0.287] CV=1.4% | 7.503 [7.449, 7.537] CV=0.5% | 0.136 [0.130, 0.138] CV=2.1% | 26.024 [25.934, 26.855] CV=1.4% / 27.000 [27.000, 27.000] CV=0.0% | 0 [0, 0] CV=0.0% | 0 [0, 0] CV=0.0% |
| Spring WebFlux + Reactor Netty + WebClient | high | 35.431 [35.317, 35.631] CV=0.3% | 0.354 [0.353, 0.356] CV=0.3% | 18.373 [18.336, 18.439] CV=0.2% | 1.600 [1.570, 1.622] CV=1.5% | 20.201 [20.189, 20.238] CV=0.1% / 21.000 [21.000, 21.000] CV=0.0% | 0 [0, 0] CV=0.0% | 0 [0, 0] CV=0.0% |
| Spring WebFlux + Reactor Netty + WebClient | moderate | 22.193 [21.493, 22.777] CV=2.1% | 0.222 [0.215, 0.228] CV=2.1% | 4.521 [4.501, 4.583] CV=0.7% | 0.070 [0.068, 0.071] CV=1.8% | 21.000 [21.000, 21.000] CV=0.0% / 21.000 [21.000, 21.000] CV=0.0% | 0 [0, 0] CV=0.0% | 0 [0, 0] CV=0.0% |

## Paired deltas

`WebFlux − MVC`; negative resource/latency deltas favor WebFlux, while positive throughput deltas favor WebFlux.

### high — 4 complete pairs

| Metric | Absolute paired delta | Paired delta % |
|---|---:|---:|
| `rps` | 0.001 [-0.008, 0.001] CV=299.1% | 0.000 [-0.006, 0.001] CV=299.1% |
| `avg_ms` | -1.132 [-1.752, -0.480] CV=41.1% | -0.179 [-0.277, -0.076] CV=41.0% |
| `p95_ms` | -2.679 [-3.562, -1.817] CV=31.1% | -0.345 [-0.458, -0.234] CV=31.0% |
| `p99_ms` | -6.287 [-12.607, -2.556] CV=52.3% | -0.768 [-1.523, -0.313] CV=51.8% |
| `cpu_avg_percent` | -18.278 [-22.635, -16.592] CV=11.9% | -33.283 [-40.368, -30.691] CV=10.5% |
| `memory_peak_delta_mib` | -108.200 [-113.600, -106.700] CV=2.5% | -44.828 [-45.550, -44.237] CV=1.4% |
| `jfr_cpu_one_core_percent` | -20.312 [-29.520, -19.444] CV=18.4% | -36.368 [-45.463, -35.508] CV=10.6% |
| `jfr_allocation_pressure_mib_s` | -16.569 [-16.650, -16.361] CV=0.7% | -47.448 [-47.533, -47.014] CV=0.4% |
| `jfr_gc_pause_ratio_percent` | 0.092 [0.031, 0.182] CV=54.5% | 6.115 [2.015, 12.640] CV=56.9% |
| `jfr_platform_threads_max` | -31.000 [-33.000, -30.000] CV=3.5% | -59.615 [-61.111, -58.824] CV=1.4% |

### moderate — 4 complete pairs

| Metric | Absolute paired delta | Paired delta % |
|---|---:|---:|
| `rps` | 0.001 [-0.016, 0.017] CV=1553.0% | 0.004 [-0.066, 0.070] CV=1576.0% |
| `avg_ms` | -0.741 [-0.909, -0.683] CV=12.0% | -0.117 [-0.143, -0.107] CV=11.8% |
| `p95_ms` | -1.099 [-1.206, -0.643] CV=21.6% | -0.141 [-0.156, -0.083] CV=21.7% |
| `p99_ms` | 0.117 [-3.984, 2.142] CV=566.0% | 0.014 [-0.490, 0.263] CV=563.8% |
| `cpu_avg_percent` | -6.934 [-7.325, -5.784] CV=9.1% | -24.800 [-26.088, -20.322] CV=9.4% |
| `memory_peak_delta_mib` | -6.850 [-44.900, 11.300] CV=196.0% | -8.170 [-49.778, 15.915] CV=220.5% |
| `jfr_cpu_one_core_percent` | -5.854 [-6.178, -5.317] CV=5.3% | -20.726 [-22.326, -19.200] CV=5.4% |
| `jfr_allocation_pressure_mib_s` | -2.954 [-3.026, -2.931] CV=1.2% | -39.424 [-40.205, -39.198] CV=1.0% |
| `jfr_gc_pause_ratio_percent` | -0.067 [-0.069, -0.060] CV=5.3% | -48.840 [-50.556, -45.881] CV=3.5% |
| `jfr_platform_threads_max` | -6.000 [-6.000, -6.000] CV=0.0% | -22.222 [-22.222, -22.222] CV=0.0% |

## Interpretation guardrails

- Docker metrics are computed only from samples timestamped inside the exact k6 process window.
- The stats collector is lifecycle-controlled and joined before summary and manifest creation.
- `dropped_iterations > 0` invalidates a controlled arrival-rate run.
- Deterministic workload identity and simulator seed make both implementations receive the same synthetic delay sequence within each pair.
- Per-request success logs are disabled in quantitative runs; observability-rich logging belongs in a separate diagnostic scenario.
- Allocation pressure is based on `ObjectAllocationSample.weight`; it is an estimate, not retained heap.
- JFR CPU is sampling-based. `CPU one-core %` converts host-capacity percentage to Docker's one-core-is-100% convention.
- Four or more balanced pairs support descriptive paired analysis; they do not turn a local lab into a universal production benchmark.
