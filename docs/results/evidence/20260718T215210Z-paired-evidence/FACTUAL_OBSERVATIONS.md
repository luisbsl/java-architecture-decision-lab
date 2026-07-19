# Automatically Generated Factual Observations

> Generated observations describe measured medians only. They intentionally avoid causal explanations and architectural recommendations.

### Scenario `high`

- **high — achieved request rate:** WebFlux median was approximately equal to MVC (149.102 req/s vs 149.105 req/s; 0.00% difference).
- **high — p95 latency:** WebFlux median was lower than MVC (773.771 ms vs 776.450 ms; 0.35% lower).
- **high — p99 latency:** WebFlux median was lower than MVC (813.505 ms vs 818.704 ms; 0.64% lower).
- **high — Docker CPU:** WebFlux median was lower than MVC (36.634 % vs 54.913 %; 33.29% lower).
- **high — container memory peak delta:** WebFlux median was lower than MVC (134.900 MiB vs 241.950 MiB; 44.24% lower).
- **high — JFR CPU in one-core convention:** WebFlux median was lower than MVC (35.431 % vs 55.853 %; 36.56% lower).
- **high — allocation pressure:** WebFlux median was lower than MVC (18.373 MiB/s vs 34.911 MiB/s; 47.37% lower).
- **high — GC pause ratio:** WebFlux median was higher than MVC (1.600 % vs 1.508 %; 6.05% higher).
- **high — maximum active platform threads:** WebFlux median was lower than MVC (21.000 threads vs 52.000 threads; 59.62% lower).
- **high — error rate:** MVC median `0.000%`; WebFlux median `0.000%`.
- **high — Virtual Thread pinning events:** MVC median `0`; WebFlux median `0`.
- **high — JFR data-loss events:** MVC median `0`; WebFlux median `0`.

### Scenario `moderate`

- **moderate — achieved request rate:** WebFlux median was approximately equal to MVC (24.724 req/s vs 24.723 req/s; 0.00% difference).
- **moderate — p95 latency:** WebFlux median was lower than MVC (774.422 ms vs 775.275 ms; 0.11% lower).
- **moderate — p99 latency:** WebFlux median was lower than MVC (810.702 ms vs 811.674 ms; 0.12% lower).
- **moderate — Docker CPU:** WebFlux median was lower than MVC (21.015 % vs 28.189 %; 25.45% lower).
- **moderate — container memory peak delta:** WebFlux median was lower than MVC (66.900 MiB vs 74.400 MiB; 10.08% lower).
- **moderate — JFR CPU in one-core convention:** WebFlux median was lower than MVC (22.193 % vs 27.767 %; 20.07% lower).
- **moderate — allocation pressure:** WebFlux median was lower than MVC (4.521 MiB/s vs 7.503 MiB/s; 39.74% lower).
- **moderate — GC pause ratio:** WebFlux median was lower than MVC (0.070 % vs 0.136 %; 48.64% lower).
- **moderate — maximum active platform threads:** WebFlux median was lower than MVC (21.000 threads vs 27.000 threads; 22.22% lower).
- **moderate — error rate:** MVC median `0.000%`; WebFlux median `0.000%`.
- **moderate — Virtual Thread pinning events:** MVC median `0`; WebFlux median `0`.
- **moderate — JFR data-loss events:** MVC median `0`; WebFlux median `0`.

Supporting artifacts:

- [`COMPARISON.md`](COMPARISON.md)
- [`comparison-aggregates.json`](comparison-aggregates.json)
- [Per-run documents](README.md#run-documents)

## Human review boundary

The generator does not write causal inference, alternative explanations, limitations, or architectural decisions. Add those to `docs/results/01-loom-vs-reactive-analysis.md` after reviewing the raw and curated evidence.
