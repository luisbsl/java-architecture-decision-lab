package io.github.luisbsl.archlab.checkout.mvc.domain;

import java.math.BigDecimal;
import java.time.Instant;

public record ConfirmedOrder(
    String orderId,
    String customerId,
    BigDecimal total,
    String currency,
    String authorizationId,
    Instant confirmedAt) {}
