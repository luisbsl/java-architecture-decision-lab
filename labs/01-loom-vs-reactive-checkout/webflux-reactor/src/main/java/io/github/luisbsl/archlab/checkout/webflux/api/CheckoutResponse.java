package io.github.luisbsl.archlab.checkout.webflux.api;

import java.math.BigDecimal;
import java.time.Instant;

public record CheckoutResponse(
    String orderId,
    String status,
    String authorizationId,
    BigDecimal total,
    String currency,
    Instant processedAt) {}
