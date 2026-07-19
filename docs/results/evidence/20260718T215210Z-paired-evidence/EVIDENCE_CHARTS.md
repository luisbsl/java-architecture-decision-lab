# Generated Evidence Charts

- Suite: `20260718T215210Z-paired-evidence`
- Canonical source: [`comparison-aggregates.json`](comparison-aggregates.json)
- Semantics: medians across four isolated runs per implementation and scenario.
- These diagrams are generated projections, not an independent evidence source.

## p95 latency

```mermaid
xychart-beta
    title "p95 latency"
    x-axis ["Moderate MVC", "Moderate WebFlux", "High MVC", "High WebFlux"]
    y-axis "milliseconds" 0 --> 892.917
    bar [775.275, 774.422, 776.450, 773.771]
```

## Application CPU

```mermaid
xychart-beta
    title "Docker application CPU"
    x-axis ["Moderate MVC", "Moderate WebFlux", "High MVC", "High WebFlux"]
    y-axis "percent" 0 --> 63.149
    bar [28.189, 21.015, 54.913, 36.634]
```

## JFR allocation pressure

```mermaid
xychart-beta
    title "JFR allocation pressure"
    x-axis ["Moderate MVC", "Moderate WebFlux", "High MVC", "High WebFlux"]
    y-axis "MiB per second" 0 --> 40.147
    bar [7.503, 4.521, 34.911, 18.373]
```

## Measured-window memory growth

```mermaid
xychart-beta
    title "Application memory peak delta"
    x-axis ["Moderate MVC", "Moderate WebFlux", "High MVC", "High WebFlux"]
    y-axis "MiB" 0 --> 278.242
    bar [74.400, 66.900, 241.950, 134.900]
```

## Maximum platform threads

```mermaid
xychart-beta
    title "Maximum active platform threads"
    x-axis ["Moderate MVC", "Moderate WebFlux", "High MVC", "High WebFlux"]
    y-axis "threads" 0 --> 59.800
    bar [27.000, 21.000, 52.000, 21.000]
```

## Interpretation boundary

Mermaid charts replace neither raw JFR nor structured JSON/CSV. They also cannot create missing incident-response, stack-trace, or human-debugging evidence.
