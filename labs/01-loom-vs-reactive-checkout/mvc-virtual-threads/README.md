# Spring MVC + Virtual Threads Checkout

This module implements the lab's Order Checkout Flow with blocking APIs and a sequential programming model, while Spring Boot dispatches request handling on Java 21 virtual threads.

## Why this implementation exists

The module makes the thread-per-request model inspectable without presenting virtual threads as a universal winner. The principal flow deliberately remains sequential so later measurements focus on concurrency across requests rather than a different intra-request algorithm.

## Run

```bash
./mvnw -pl labs/01-loom-vs-reactive-checkout/mvc-virtual-threads -am spring-boot:run
```

Requirements:

- simulator at `http://localhost:8083`;
- checkout API at `http://localhost:8081`.

```bash
BASE_URL=http://localhost:8081 \
  ./labs/01-loom-vs-reactive-checkout/scripts/checkout-smoke-test.sh
```

## Controlled local operations

- persistence delay: `PERSISTENCE_DELAY`, default `40ms`;
- event publication delay: `EVENT_PUBLICATION_DELAY`, default `20ms`;
- simulator base URL: `SIMULATOR_BASE_URL`;
- downstream read timeout: `DOWNSTREAM_READ_TIMEOUT`, default `2s`.

## What this module does not prove

- virtual threads reduce individual request latency;
- blocking code is always simpler in every domain;
- downstream capacity stops being a constraint;
- this local in-memory persistence model represents a database.
