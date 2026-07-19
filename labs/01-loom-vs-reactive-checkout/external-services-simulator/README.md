# External Services Simulator

A small Spring Boot application that provides controlled customer, inventory, and payment dependencies for both checkout implementations.

## Why a dedicated simulator?

A shared simulator keeps the two implementations focused on the same business flow and allows latency and failures to be configured without relying on external systems.

## Run

From the repository root:

```bash
./mvnw -pl labs/01-loom-vs-reactive-checkout/external-services-simulator spring-boot:run
```

## Configuration

| Environment variable | Default |
|---|---:|
| `CUSTOMER_MIN_DELAY` | `80ms` |
| `CUSTOMER_MAX_DELAY` | `150ms` |
| `CUSTOMER_FAILURE_RATE` | `0.00` |
| `INVENTORY_MIN_DELAY` | `100ms` |
| `INVENTORY_MAX_DELAY` | `250ms` |
| `INVENTORY_FAILURE_RATE` | `0.00` |
| `PAYMENT_MIN_DELAY` | `150ms` |
| `PAYMENT_MAX_DELAY` | `400ms` |
| `PAYMENT_FAILURE_RATE` | `0.00` |

## Contract

### Customer

```http
GET /api/customers/{customerId}
```

### Inventory

```http
GET /api/inventory/{sku}?quantity=2
```

### Payment

```http
POST /api/payments/authorize
Content-Type: application/json

{
  "orderId": "order-001",
  "customerId": "customer-001",
  "amount": 149.90,
  "currency": "BRL"
}
```

Failures are returned as RFC 9457-style problem details through Spring's `ProblemDetail` API.
