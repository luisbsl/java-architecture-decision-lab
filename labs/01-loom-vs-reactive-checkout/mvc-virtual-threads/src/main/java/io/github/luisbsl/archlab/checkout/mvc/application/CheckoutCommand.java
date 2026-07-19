package io.github.luisbsl.archlab.checkout.mvc.application;

import java.util.List;

public record CheckoutCommand(
    String orderId,
    String customerId,
    List<CheckoutItem> items,
    String currency) {}
