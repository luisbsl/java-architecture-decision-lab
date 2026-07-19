# Loom vs Reactive Checkout — Comparative Analysis

> **Measurement status: quantitative suite complete and audited.**
>
> This analysis applies only to suite `20260718T215210Z-paired-evidence`, commit `14d95f82c6557a7cf5005d80dc2536923aa91ecf`, protocol version `4`, the documented host, the documented container limits, and the profiler-enabled configuration.
>
> **This is not a definitive benchmark.** The compared units are complete stacks:
>
> - Spring MVC + Tomcat + Virtual Threads + JDK HttpClient;
> - Spring WebFlux + Reactor Netty + WebClient.

## Architectural question

For the same sequential request/response Order Checkout Flow dominated by downstream waiting, how do Spring MVC + Virtual Threads and Spring WebFlux + Reactor change:

- programming model and cognitive load;
- schedule adherence and latency distribution under controlled arrival rates;
- CPU, memory, allocation, GC, and platform-thread behavior;
- debugging, context propagation, and operational investigation;
- maintainability and long-term architectural fit?

## Hypotheses — written before measurement

### MVC + Virtual Threads

- **Expected strengths:** direct imperative control flow, ordinary exception propagation, linear debugging experience, straightforward integration with blocking APIs, and competitive behavior for I/O-bound request/response workloads.
- **Expected risks:** higher support-thread footprint, greater allocation pressure, higher memory use, and possible Virtual Thread pinning if synchronized/native blocking sections were exercised.
- **Evidence that would challenge the expectation:** dropped iterations, materially worse latency at the controlled rates, observed pinning, unstable resource behavior, or a code path that remained difficult to reason about despite the imperative model.

### WebFlux + Reactor

- **Expected strengths:** stable platform-thread footprint, lower CPU and allocation pressure under concurrency, explicit asynchronous composition, and strong fit with non-blocking end-to-end dependencies.
- **Expected risks:** additional operator/context/cancellation semantics, reactive types crossing application boundaries, and greater debugging and onboarding cost for teams without Reactor fluency.
- **Evidence that would challenge the expectation:** no repeatable resource-efficiency advantage, event-loop instability, dropped iterations, materially worse latency, blocking work on event-loop threads, or failure handling that became operationally opaque.

## Workload and invariants

| Variable | Formal value |
|---|---|
| Functional contract | `POST /orders/checkout` |
| Business flow | customer lookup → inventory check → payment authorization → persistence delay → event-publication delay |
| Suite | `20260718T215210Z-paired-evidence` |
| Git SHA | `14d95f82c6557a7cf5005d80dc2536923aa91ecf` |
| Protocol | version `4`; fingerprint `a4fed544463e5208363a99e9d866875205ec63bff916440742f817b4b417fe63` |
| Scenarios | `moderate` at 25 iterations/s; `high` at 150 iterations/s |
| Repetitions | four balanced pairs per scenario; 16 isolated runs total |
| Pair order | odd pairs MVC→WebFlux; even pairs WebFlux→MVC |
| Workload seed | `20260718`; deterministic simulator enabled |
| Warm-up | 20 seconds per run |
| Measured window | 60 seconds for `moderate`; 120 seconds for `high` |
| App limits | 2 CPUs and 1 GiB per application container |
| Simulator limits | 2 CPUs and 1 GiB |
| Failure rate | payment failure rate `0.00` |
| Downstream timeout | 2 seconds |
| Quantitative logging | `WARN`; per-request success logging excluded |
| Profiling | bounded JFR recording and lifecycle-bounded Docker Stats |

## Environment and evidence integrity

The formal suite passed the evidence audit:

- 16 runs audited;
- zero failed runs;
- zero dropped iterations;
- zero HTTP errors;
- zero JFR data-loss events;
- zero observed Virtual Thread pinning events;
- per-run manifests and suite manifest validated;
- three accepted one-iteration scheduler-boundary warnings, each within the formal `±1` cutoff tolerance.

Primary evidence:

- [`evidence/20260718T215210Z-paired-evidence/SUITE_AUDIT.md`](evidence/20260718T215210Z-paired-evidence/SUITE_AUDIT.md)
- [`evidence/20260718T215210Z-paired-evidence/COMPARISON.md`](evidence/20260718T215210Z-paired-evidence/COMPARISON.md)
- [`evidence/20260718T215210Z-paired-evidence/FACTUAL_OBSERVATIONS.md`](evidence/20260718T215210Z-paired-evidence/FACTUAL_OBSERVATIONS.md)
- [`evidence/20260718T215210Z-paired-evidence/comparison.csv`](evidence/20260718T215210Z-paired-evidence/comparison.csv)
- [`evidence/20260718T215210Z-paired-evidence/comparison-aggregates.json`](evidence/20260718T215210Z-paired-evidence/comparison-aggregates.json)

<!-- BEGIN AUTO-GENERATED:EVIDENCE -->
## Latest generated evidence

- Suite: `20260718T215210Z-paired-evidence`
- Status: **complete and audited**
- Runs: **16 / 16**
- Scenarios: `moderate,high`
- Pairs: `4`
- Generated factual observations: [`evidence/20260718T215210Z-paired-evidence/FACTUAL_OBSERVATIONS.md`](evidence/20260718T215210Z-paired-evidence/FACTUAL_OBSERVATIONS.md)
- Generated comparison: [`evidence/20260718T215210Z-paired-evidence/COMPARISON.md`](evidence/20260718T215210Z-paired-evidence/COMPARISON.md)
<!-- END AUTO-GENERATED:EVIDENCE -->

## Decision-relevant quantitative summary

Medians across four isolated runs per implementation and scenario:

| Scenario | Metric | MVC + Virtual Threads | WebFlux/Reactor | WebFlux relative to MVC |
|---|---|---:|---:|---:|
| high | Achieved request rate | 149.105 req/s | 149.102 req/s | approximately equal |
| high | p95 latency | 776.450 ms | 773.771 ms | 0.35% lower |
| high | p99 latency | 818.704 ms | 813.505 ms | 0.64% lower |
| high | Docker app CPU | 54.913% | 36.634% | 33.29% lower |
| high | JFR CPU, one-core convention | 55.853% | 35.431% | 36.56% lower |
| high | Allocation pressure | 34.911 MiB/s | 18.373 MiB/s | 47.37% lower |
| high | App memory peak delta | 241.950 MiB | 134.900 MiB | 44.24% lower |
| high | Max active platform threads | 52 | 21 | 59.62% lower |
| moderate | Achieved request rate | 24.723 req/s | 24.724 req/s | approximately equal |
| moderate | p95 latency | 775.275 ms | 774.422 ms | 0.11% lower |
| moderate | JFR CPU, one-core convention | 27.767% | 22.193% | 20.07% lower |
| moderate | Allocation pressure | 7.503 MiB/s | 4.521 MiB/s | 39.74% lower |
| moderate | Max active platform threads | 27 | 21 | 22.22% lower |

The complete median, range, coefficient-of-variation, and paired-delta tables remain generated artifacts and are not copied manually here.

## JVM and profiler observations

### MVC + Virtual Threads

| Observation | Supporting evidence | Interpretation | Limitation |
|---|---|---|---|
| No Virtual Thread pinning event was observed in any run. | `jfr_virtual_thread_pinned_count=0` for all MVC runs; per-run `JFR_METRICS.md`. | The tested blocking operations did not produce pinning above the configured JFR threshold. Virtual Threads were able to park rather than hold carriers during the observed waits. | Absence of an observed event is not proof that every library path is pin-safe. The suite did not exercise synchronized/native hotspots, JDBC drivers, or arbitrary production integrations. |
| Platform-thread maximum increased from 27 in `moderate` to a median of 52 in `high`. | Generated JFR tables in `COMPARISON.md`. | The complete MVC/Tomcat/JDK HttpClient stack used a larger support/platform-thread footprint as concurrency increased, even though request work ran on Virtual Threads. | The metric does not isolate Tomcat, JDK HttpClient, scheduler, GC, profiler, and framework contributions. It is not a count of active Virtual Threads. |
| Allocation pressure was approximately 7.50 MiB/s in `moderate` and 34.91 MiB/s in `high`. | JFR weighted allocation samples. Representative high-run allocation sites include `InputStream.transferTo`, `Throwable.fillInStackTrace`, `Continuation.doYield`, Jackson buffers, and JDK HttpClient internals. | The imperative stack remained operationally stable but generated materially more sampled allocation weight than the reactive stack in this implementation. | JFR allocation sampling estimates allocated bytes; it is not retained heap and does not prove which single component caused the difference. |
| High-scenario app memory peak delta was consistently around 240–250 MiB. | Docker measured-window table; low CV across four high runs. | The high-load memory difference is repeatable enough to be decision-relevant for this host and stack configuration. | Docker memory includes the complete process and runtime. It does not attribute memory specifically to Virtual Threads. |
| GC pause ratio was low in both scenarios: approximately 0.136% in `moderate` and 1.508% in `high`. | Structured JFR evidence. | The higher allocation rate did not translate into catastrophic pause behavior during the measured windows. | Short local windows can align differently with GC cycles; pause ratio alone does not describe heap occupancy, long-run stability, or tail behavior under hours of load. |

### WebFlux + Reactor

| Observation | Supporting evidence | Interpretation | Limitation |
|---|---|---|---|
| Platform-thread maximum remained at 21 in every run and both scenarios. | Generated JFR tables; CV 0%. | The Reactor Netty stack maintained a stable platform-thread footprint as the configured arrival rate increased from 25 to 150 iterations/s. | This workload did not include blocking adapters, `boundedElastic` offloading, streaming, or mixed blocking/reactive libraries that could change the thread model. |
| CPU was lower in all paired comparisons. | Docker paired deltas: roughly 20–26% lower in `moderate` and 31–40% lower in `high`; JFR CPU showed the same direction in every pair. | For the implemented full stack, WebFlux used less CPU to sustain the same controlled arrival rate. | This is not Reactor-only evidence. Netty vs Tomcat, WebClient vs JDK HttpClient, timer implementation, serialization paths, and framework defaults are part of the result. |
| Allocation pressure was lower in every pair, by approximately 39–40% in `moderate` and 47% in `high`. | JFR paired deltas and allocation reports. Representative sites include Reactor Netty operations, Netty headers, arrays, maps, and stack-trace allocation. | Lower allocation pressure is the most stable resource-efficiency difference in the suite. | Sampled allocation does not establish retained-memory behavior or universal superiority across payloads and operator graphs. |
| High-scenario memory peak delta was consistently about 44% lower. | Docker measured-window pair deltas; narrow high-scenario range. | Under the high controlled rate, the reactive stack required materially less additional container memory in this setup. | The moderate-scenario memory samples were noisy and sometimes reversed direction; the memory conclusion should therefore be scoped primarily to the high scenario. |
| GC pause ratio was lower in `moderate` but slightly higher in `high`. | Median 0.070% vs 0.136% in moderate; 1.600% vs 1.508% in high. | Lower allocation does not imply an automatic pause-ratio win in every short window. The high-scenario absolute difference was only about 0.092 percentage points. | Four short recordings are insufficient for causal GC conclusions. Heap ergonomics and cycle alignment may explain part of the variation. |

## Findings

### Finding 1 — Both implementations satisfied the controlled workload

**Observation:** Both stacks sustained approximately 24.72 req/s in `moderate` and 149.10 req/s in `high`, with zero dropped iterations, zero HTTP errors, and essentially identical schedule adherence.

**Supporting artifacts:** `COMPARISON.md`, `comparison.csv`, all per-run `run-summary.json`, and `SUITE_AUDIT.md`.

**Inference:** At the two configured arrival rates, neither implementation showed evidence of saturation or inability to serve the defined sequential checkout flow.

**Alternative explanation:** The shared simulator, client-side arrival scheduler, container limits, or downstream delays may have constrained the shape of the result before either application stack reached its own capacity limit.

**Limitation:** These were controlled arrival-rate scenarios, not a capacity search. Achieved request rate here measures schedule adherence, not maximum throughput.

**Decision implication for this workload:** Throughput does not select the architecture at these rates. Resource efficiency, programming model, operational fit, and maintainability become the relevant differentiators.

### Finding 2 — End-to-end latency was materially equivalent

**Observation:** WebFlux had small median latency advantages: about 0.11–0.35% at p95 and 0.64% at p99 in `high`; `moderate` p99 paired results changed direction across runs.

**Supporting artifacts:** HTTP medians and paired-delta tables in `COMPARISON.md`.

**Inference:** The concurrency model did not materially change user-visible latency for this workload. The shared deterministic downstream waits dominated the response time.

**Alternative explanation:** A larger or more CPU-intensive payload, a different HTTP client configuration, connection-pool pressure, timeouts, or saturation could amplify stack differences.

**Limitation:** The simulator is synthetic and local. No real network variance, TLS, database pool, broker, or remote service was present.

**Decision implication for this workload:** A sub-1% latency difference is not a sound reason to choose either stack here.

### Finding 3 — WebFlux was consistently more CPU- and allocation-efficient

**Observation:** WebFlux used less Docker CPU and JFR-normalized CPU in every balanced pair. Allocation pressure was lower in all eight pairs, with narrow variation.

**Supporting artifacts:** paired deltas in `COMPARISON.md`; per-run JFR metrics and allocation reports.

**Inference:** The complete Reactor Netty/WebClient implementation performed the same controlled work with lower runtime resource pressure on this host.

**Alternative explanation:** The difference may be driven partly by JDK HttpClient, RestClient response handling, Tomcat support infrastructure, Virtual Thread continuation/stack-chunk costs, timer implementation, or other full-stack differences—not by the abstract reactive model alone.

**Limitation:** The lab intentionally compares deployable stacks, not isolated concurrency primitives. It cannot attribute the delta to one framework or JVM mechanism.

**Decision implication for this workload:** In a high-concurrency, resource-constrained service that is non-blocking end to end, WebFlux has a credible efficiency advantage that should be weighed against its engineering complexity.

### Finding 4 — Virtual Threads preserved the imperative model without observed pinning

**Observation:** MVC completed all runs with zero observed pinning and zero dropped iterations while keeping the business flow synchronous and sequential.

**Supporting artifacts:** JFR pinning metrics; MVC `CheckoutService`; synchronous application ports; audit report.

**Inference:** For the tested APIs and synthetic waits, Virtual Threads made a conventional thread-per-request programming style operationally viable at the configured concurrency.

**Alternative explanation:** The selected JDK HTTP client and `Thread.sleep` paths are friendly to Virtual Threads. Production libraries with synchronized blocks, native calls, or pool constraints may behave differently.

**Limitation:** The suite did not include JDBC, legacy synchronized libraries, native integrations, or pinned-carrier stress cases.

**Decision implication for this workload:** Teams can retain ordinary imperative code without the platform-thread-per-request scalability constraint, but they must still profile library behavior and external bottlenecks.

### Finding 5 — The high-scenario memory difference is credible; the moderate difference is not stable enough

**Observation:** At `high`, WebFlux memory peak delta was about 44% lower in every pair with low variability. At `moderate`, pair deltas ranged from a large WebFlux advantage to a small MVC advantage.

**Supporting artifacts:** Docker memory tables and paired deltas.

**Inference:** The high-load memory difference is repeatable for this configuration; the moderate-load memory result is sensitive to baseline and short-window runtime state.

**Alternative explanation:** JVM startup state, class loading, heap expansion timing, GC cycle position, and container sampling cadence can strongly affect short-run peak deltas.

**Limitation:** Peak delta is not retained heap, live-set size, or long-duration steady state.

**Decision implication for this workload:** Use the high-scenario result as local sizing evidence, but do not use the moderate result as a general memory claim.

### Finding 6 — Balanced order reduced, but did not eliminate, local-run bias

**Observation:** Odd pairs executed MVC first and even pairs executed WebFlux first. Stable metrics—allocation, platform threads, and CPU direction—remained consistent across both orders.

**Supporting artifacts:** `suite.env`, `comparison.csv`, paired deltas.

**Inference:** The strongest resource findings are unlikely to be explained solely by which stack ran first.

**Alternative explanation:** Only two observations per implementation/order combination exist in each scenario, and longer-lived host effects may remain.

**Limitation:** The protocol did not randomize order beyond the fixed alternation and did not run on multiple hosts or days.

**Decision implication for this workload:** Treat the direction of large, low-variance deltas as credible descriptive evidence, while keeping claims local and non-causal.

## Code and cognitive-load evidence

The code comparison supports an architectural trade-off that the numeric suite cannot express by itself.

### MVC + Virtual Threads

- The happy path is a direct sequence in `CheckoutService`: lookup customer, loop through inventory, authorize payment, create order, save, publish, return.
- Application ports expose domain values and `void`, so the application boundary is not coupled to a concurrency library.
- Ordinary exceptions interrupt control flow at the point of failure.
- Correlation context is read through the request-thread context used by the servlet filter.
- Blocking delays model persistence and publication with an explicit interruption path that restores the interrupt flag.
- Unit tests use direct return values and synchronous exception assertions.

### WebFlux/Reactor

- The same flow requires `Mono.defer`, `deferContextual`, `switchIfEmpty`, `flatMap`, `then`, `thenReturn`, `Flux.concatMap`, and Reactor Context propagation.
- `Mono` appears in the use-case and every application port, coupling those boundaries to Reactor semantics.
- Empty publishers require explicit semantic treatment in addition to ordinary error signals.
- Correlation context must be propagated through Reactor Context rather than relying on a request-thread local.
- Persistence and publication delays use asynchronous timers and become part of the publisher chain.
- Unit tests require publishers, Reactor Context, and `StepVerifier`.

### Interpretation

**Observation:** The imperative flow is visually closer to the business sequence; the reactive flow carries additional composition and context-propagation semantics.

**Inference:** MVC + Virtual Threads imposes a lower model-specific cognitive cost for this strictly sequential request/response use case. WebFlux pays more complexity in exchange for stable thread usage, explicit asynchronous composition, and lower measured resource pressure.

**Alternative explanation:** A team deeply fluent in Reactor may experience much less practical cognitive cost, and a domain built around streams, fan-out, cancellation, or backpressure may make reactive composition the more natural model.

**Limitation:** Line count is deliberately not used as proof. The test suites are not coverage-identical, and code familiarity cannot be measured from the repository alone.

**Architectural implication:** The choice should account for the team's operating model and the nature of the domain, not only runtime metrics.

## Debugging and operational evidence

The quantitative suite used `BENCHMARK_LOG_LEVEL=WARN`, payment failure rate `0.00`, and no forced timeout path. Therefore it does **not** provide defensible evidence for:

- actual stack-trace shape during a slow payment dependency;
- measured time to identify the degraded dependency;
- comparative operator assembly traces;
- cancellation behavior during a timeout;
- human investigation speed;
- VisualVM/JMC usability during an incident.

These topics must be completed from the separate diagnostic sessions defined in the runbook. Until those artifacts exist, the following remain **code-based expectations, not measured findings**:

### MVC + Virtual Threads — expectation to validate

- likely more linear application stack trace through controller, use case, gateway, and synchronous HTTP client;
- correlation ID propagation follows the request execution context;
- interruption and timeout handling should be visible through ordinary exception paths;
- expected operational advantage: easier local stepping and familiar call-stack navigation;
- risk to validate: large numbers of parked Virtual Threads and support threads may require appropriate tooling views.

### WebFlux/Reactor — expectation to validate

- stack traces may emphasize subscriber/operator boundaries unless Reactor debugging/observability support is enabled;
- correlation ID depends on correct Reactor Context propagation across every asynchronous boundary;
- cancellation and timeout semantics are expressible in the pipeline but require operator-level understanding;
- expected operational advantage: event-loop and connection behavior are explicit in Reactor Netty tooling;
- risk to validate: incident responders may need deeper framework knowledge to reconstruct the logical call chain.

No final debugging winner is recorded in v1.0.0. Diagnostic evidence remains a separately versioned future extension and is not required for the quantitative and code-analysis conclusions published here.

## What the evidence suggests

For this deterministic, sequential, I/O-bound checkout flow at 25 and 150 controlled iterations per second:

1. Both implementations met the configured workload with equivalent end-to-end latency and no functional errors.
2. WebFlux/Reactor was materially more efficient in CPU, allocation pressure, high-scenario memory growth, and platform-thread footprint.
3. MVC + Virtual Threads remained fully viable and avoided observed pinning while preserving a simpler imperative application flow.
4. The runtime-efficiency advantage did not translate into a meaningful latency advantage because downstream waiting dominated the request.
5. The result is a trade-off, not a universal winner: WebFlux bought resource efficiency with a more specialized programming and operational model; MVC + Virtual Threads bought simplicity with higher measured runtime cost in this stack.

## What the evidence does not prove

- that Loom is always better or worse than Reactor;
- that WebFlux is obsolete or universally more efficient;
- that a local host represents production;
- that either stack has reached maximum throughput;
- that Virtual Threads automatically reduce individual request latency;
- that fewer platform threads alone imply a better architecture;
- that the observed resource delta is caused by one framework rather than the complete stack;
- that no pinning can occur with production libraries not exercised here;
- that the short-run memory peak represents retained heap or long-duration steady state;
- that debugging and incident response are better in either stack before separate diagnostic evidence exists;
- that these results transfer unchanged to streaming, backpressure, CPU-bound work, JDBC pools, brokers, TLS, remote networks, or different payloads.

## Contextual decision record

### When MVC + Virtual Threads would be the stronger fit

MVC + Virtual Threads is the stronger default when most of the following are true:

- the domain is conventional request/response and primarily sequential;
- the ecosystem contains blocking APIs such as JDBC, legacy SDKs, synchronous HTTP clients, or enterprise libraries;
- team fluency, onboarding speed, debugger familiarity, and linear stack traces are high-priority constraints;
- resource headroom can absorb the higher CPU/allocation/memory footprint observed in this lab;
- the service does not require backpressure or continuous streaming as a core domain behavior;
- operational simplicity and code locality are more valuable than maximizing per-container concurrency density;
- profiling confirms that critical libraries do not cause harmful pinning or external-pool saturation.

For this checkout flow, MVC + Virtual Threads is architecturally credible because the business sequence is naturally imperative and the controlled workload completed without errors, drops, or pinning. Its cost is the higher measured resource pressure of the complete stack.

### When WebFlux/Reactor would remain the stronger fit

WebFlux/Reactor remains the stronger fit when most of the following are true:

- dependencies are non-blocking end to end;
- container density, CPU efficiency, allocation rate, and stable platform-thread usage are major constraints;
- the domain benefits from streams, backpressure, cancellation, fan-out/fan-in, or long-lived connections;
- the existing platform and libraries are already reactive;
- the team is proficient in Reactor operators, Context propagation, testing, debugging, and event-loop safety;
- blocking calls can be excluded or isolated deliberately;
- the measured resource advantage justifies the additional engineering model.

For this checkout flow, WebFlux has a strong local efficiency case: it served the same workload with substantially lower CPU and allocation pressure, and with a stable 21-thread platform footprint. The architectural price is the reactive model crossing application boundaries and increasing operator/context semantics.

## Final takeaway

> Project Loom did not make the reactive stack irrelevant, and the reactive stack did not make imperative code obsolete.
>
> In this lab, WebFlux/Reactor was the more resource-efficient complete stack, while MVC + Virtual Threads was the simpler application model and remained operationally viable without observed pinning.
>
> **Loom does not remove architectural trade-offs. It changes where the balance point is.**

## Deferred diagnostic evidence

The quantitative and code-analysis conclusions are ready for v1.0.0. Before presenting debugging and operability claims as measured findings in a future release, add:

- one INFO-log diagnostic run per stack;
- one controlled slow-payment or timeout path per stack;
- stack-trace and correlation-ID artifacts;
- optional VisualVM/JMC snapshots or screenshots when they add information beyond structured JFR evidence;
- a short, repeatable incident-investigation record;
- any host event that may have disturbed the diagnostic session.
