# Observability Contract — Lab 01

Both checkout implementations expose the same operational surface:

```text
/actuator/health
/actuator/health/liveness
/actuator/health/readiness
/actuator/info
/actuator/metrics
/actuator/prometheus
```

## Correlation

- inbound header: `X-Correlation-Id`;
- missing values are generated;
- the value is returned to the caller;
- the same value is propagated to the simulator;
- logs include `correlationId`, `orderId`, and `implementation` as structured fields.

## Comparable custom metrics

```text
checkout.completed
checkout.failed
checkout.duration
```

Each metric carries an `implementation` tag. JVM, HTTP server, and process metrics are supplied by Actuator/Micrometer.

## Security boundary

The lab exposes operational endpoints for local evidence collection. This is **not** production security guidance. A real deployment must deliberately restrict network access, authentication, authorization, data exposure, and metric cardinality.

## Health limitation

Readiness includes the synthetic simulator because it is required by the checkout flow. This does not mean every production dependency should always be queried synchronously by a health endpoint.
