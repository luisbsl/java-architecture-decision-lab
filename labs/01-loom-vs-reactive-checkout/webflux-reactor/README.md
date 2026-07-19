# Spring WebFlux + Reactor Checkout

This module implements the same Order Checkout Flow and public JSON contract as the MVC module, using non-blocking `WebClient` calls and Reactor composition.

## Comparison discipline

The business sequence remains customer -> inventory -> payment -> persistence -> event publication. The lab does not introduce a different parallel algorithm here, because that would change more than the programming/concurrency model.

## Run

```bash
./mvnw -pl labs/01-loom-vs-reactive-checkout/webflux-reactor -am spring-boot:run
```

Requirements:

- simulator at `http://localhost:8083`;
- checkout API at `http://localhost:8082`.

```bash
BASE_URL=http://localhost:8082 \
  ./labs/01-loom-vs-reactive-checkout/scripts/checkout-smoke-test.sh
```

## Controlled local operations

The same environment variables and default delays used by the MVC implementation are supported.

## What this module does not prove

- WebFlux is a universal default for request/response APIs;
- this checkout demonstrates streaming or backpressure advantages;
- fewer platform threads automatically mean lower total cost;
- non-blocking code removes downstream bottlenecks.
