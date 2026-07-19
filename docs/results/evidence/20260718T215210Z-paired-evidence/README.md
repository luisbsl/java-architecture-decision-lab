# Curated Evidence — `20260718T215210Z-paired-evidence`

> Generated automatically from immutable run summaries and structured JFR metrics. Do not edit generated tables manually.

## Publication status

- Status: **complete**
- Completed runs: **16** / **16**
- Suite ID: `20260718T215210Z-paired-evidence`
- Git SHA: `14d95f82c6557a7cf5005d80dc2536923aa91ecf`
- Protocol version: `4`
- Protocol fingerprint: `a4fed544463e5208363a99e9d866875205ec63bff916440742f817b4b417fe63`
- Scenarios: `moderate,high`
- Pairs: `4`

## Reproduce

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \
  --scenarios moderate,high \
  --pairs 4
```

## Generated comparison

- [`COMPARISON.md`](COMPARISON.md): full HTTP, container, JVM, GC, allocation, thread, and pinning tables.
- [`FACTUAL_OBSERVATIONS.md`](FACTUAL_OBSERVATIONS.md): neutral, automatically generated comparisons without causal claims.

## Observed median deltas

These deltas describe this machine, commit, scenario, limits, and profiler configuration. They are observations, not universal conclusions.

| Scenario | WebFlux vs MVC achieved req/s | WebFlux vs MVC p95 | WebFlux vs MVC JFR CPU one-core | WebFlux vs MVC allocation pressure |
|---|---:|---:|---:|---:|
| high | -0.00% | -0.35% | -36.56% | -47.37% |
| moderate | +0.00% | -0.11% | -20.07% | -39.74% |

## Run documents

| Pair | Order | Implementation | Scenario | Run | JFR details |
|---:|---:|---|---|---|---|
| 1 | 1 | mvc-vthreads | high | [`20260718T220811Z-pair01-order01-mvc-vthreads-high-run1`](runs/20260718T220811Z-pair01-order01-mvc-vthreads-high-run1/RUN_SUMMARY.md) | [JFR](runs/20260718T220811Z-pair01-order01-mvc-vthreads-high-run1/jfr-reports/JFR_METRICS.md) |
| 1 | 2 | webflux-reactor | high | [`20260718T221113Z-pair01-order02-webflux-reactor-high-run1`](runs/20260718T221113Z-pair01-order02-webflux-reactor-high-run1/RUN_SUMMARY.md) | [JFR](runs/20260718T221113Z-pair01-order02-webflux-reactor-high-run1/jfr-reports/JFR_METRICS.md) |
| 2 | 1 | webflux-reactor | high | [`20260718T221416Z-pair02-order01-webflux-reactor-high-run2`](runs/20260718T221416Z-pair02-order01-webflux-reactor-high-run2/RUN_SUMMARY.md) | [JFR](runs/20260718T221416Z-pair02-order01-webflux-reactor-high-run2/jfr-reports/JFR_METRICS.md) |
| 2 | 2 | mvc-vthreads | high | [`20260718T221718Z-pair02-order02-mvc-vthreads-high-run2`](runs/20260718T221718Z-pair02-order02-mvc-vthreads-high-run2/RUN_SUMMARY.md) | [JFR](runs/20260718T221718Z-pair02-order02-mvc-vthreads-high-run2/jfr-reports/JFR_METRICS.md) |
| 3 | 1 | mvc-vthreads | high | [`20260718T222020Z-pair03-order01-mvc-vthreads-high-run3`](runs/20260718T222020Z-pair03-order01-mvc-vthreads-high-run3/RUN_SUMMARY.md) | [JFR](runs/20260718T222020Z-pair03-order01-mvc-vthreads-high-run3/jfr-reports/JFR_METRICS.md) |
| 3 | 2 | webflux-reactor | high | [`20260718T222321Z-pair03-order02-webflux-reactor-high-run3`](runs/20260718T222321Z-pair03-order02-webflux-reactor-high-run3/RUN_SUMMARY.md) | [JFR](runs/20260718T222321Z-pair03-order02-webflux-reactor-high-run3/jfr-reports/JFR_METRICS.md) |
| 4 | 1 | webflux-reactor | high | [`20260718T222622Z-pair04-order01-webflux-reactor-high-run4`](runs/20260718T222622Z-pair04-order01-webflux-reactor-high-run4/RUN_SUMMARY.md) | [JFR](runs/20260718T222622Z-pair04-order01-webflux-reactor-high-run4/jfr-reports/JFR_METRICS.md) |
| 4 | 2 | mvc-vthreads | high | [`20260718T222924Z-pair04-order02-mvc-vthreads-high-run4`](runs/20260718T222924Z-pair04-order02-mvc-vthreads-high-run4/RUN_SUMMARY.md) | [JFR](runs/20260718T222924Z-pair04-order02-mvc-vthreads-high-run4/jfr-reports/JFR_METRICS.md) |
| 1 | 1 | mvc-vthreads | moderate | [`20260718T215211Z-pair01-order01-mvc-vthreads-moderate-run1`](runs/20260718T215211Z-pair01-order01-mvc-vthreads-moderate-run1/RUN_SUMMARY.md) | [JFR](runs/20260718T215211Z-pair01-order01-mvc-vthreads-moderate-run1/jfr-reports/JFR_METRICS.md) |
| 1 | 2 | webflux-reactor | moderate | [`20260718T215411Z-pair01-order02-webflux-reactor-moderate-run1`](runs/20260718T215411Z-pair01-order02-webflux-reactor-moderate-run1/RUN_SUMMARY.md) | [JFR](runs/20260718T215411Z-pair01-order02-webflux-reactor-moderate-run1/jfr-reports/JFR_METRICS.md) |
| 2 | 1 | webflux-reactor | moderate | [`20260718T215612Z-pair02-order01-webflux-reactor-moderate-run2`](runs/20260718T215612Z-pair02-order01-webflux-reactor-moderate-run2/RUN_SUMMARY.md) | [JFR](runs/20260718T215612Z-pair02-order01-webflux-reactor-moderate-run2/jfr-reports/JFR_METRICS.md) |
| 2 | 2 | mvc-vthreads | moderate | [`20260718T215811Z-pair02-order02-mvc-vthreads-moderate-run2`](runs/20260718T215811Z-pair02-order02-mvc-vthreads-moderate-run2/RUN_SUMMARY.md) | [JFR](runs/20260718T215811Z-pair02-order02-mvc-vthreads-moderate-run2/jfr-reports/JFR_METRICS.md) |
| 3 | 1 | mvc-vthreads | moderate | [`20260718T220010Z-pair03-order01-mvc-vthreads-moderate-run3`](runs/20260718T220010Z-pair03-order01-mvc-vthreads-moderate-run3/RUN_SUMMARY.md) | [JFR](runs/20260718T220010Z-pair03-order01-mvc-vthreads-moderate-run3/jfr-reports/JFR_METRICS.md) |
| 3 | 2 | webflux-reactor | moderate | [`20260718T220209Z-pair03-order02-webflux-reactor-moderate-run3`](runs/20260718T220209Z-pair03-order02-webflux-reactor-moderate-run3/RUN_SUMMARY.md) | [JFR](runs/20260718T220209Z-pair03-order02-webflux-reactor-moderate-run3/jfr-reports/JFR_METRICS.md) |
| 4 | 1 | webflux-reactor | moderate | [`20260718T220411Z-pair04-order01-webflux-reactor-moderate-run4`](runs/20260718T220411Z-pair04-order01-webflux-reactor-moderate-run4/RUN_SUMMARY.md) | [JFR](runs/20260718T220411Z-pair04-order01-webflux-reactor-moderate-run4/jfr-reports/JFR_METRICS.md) |
| 4 | 2 | mvc-vthreads | moderate | [`20260718T220611Z-pair04-order02-mvc-vthreads-moderate-run4`](runs/20260718T220611Z-pair04-order02-mvc-vthreads-moderate-run4/RUN_SUMMARY.md) | [JFR](runs/20260718T220611Z-pair04-order02-mvc-vthreads-moderate-run4/jfr-reports/JFR_METRICS.md) |

## Evidence policy

- Raw `.jfr`, full logs, granular k6 streams, heap dumps, and container inspection remain release assets.
- Per-run `source-manifest.sha256` is provenance for the raw package; validate the curated tree with `curated-manifest.sha256`.
- Published tables are generated from `run-summary.json` and `jfr-metrics.json`.
- VisualVM/JMC screenshots may supplement interpretation, but they are not the numeric source of truth.
- Manual analysis belongs in `docs/results/01-loom-vs-reactive-analysis.md`, outside generated markers.

## Guardrails

- Allocation pressure uses JFR sample weight and is not retained heap.
- Sampling identifies observed hotspots; it does not prove causality by itself.
- No pinned-thread event means none was observed above the configured threshold during the measured window.
- Arrival-rate request rates describe schedule adherence, not maximum server capacity.
- The comparison is between complete stacks, not an isolated Loom-versus-Reactor microbenchmark.
- A local profiler-enabled protocol does not represent every production environment.
