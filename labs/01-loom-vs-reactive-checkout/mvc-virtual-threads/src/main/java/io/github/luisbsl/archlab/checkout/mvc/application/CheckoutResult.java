package io.github.luisbsl.archlab.checkout.mvc.application;

import java.math.BigDecimal;
import java.time.Instant;

public record CheckoutResult(
    String orderId,
    String status,
    String authorizationId,
    BigDecimal total,
    String currency,
    Instant processedAt) {}
