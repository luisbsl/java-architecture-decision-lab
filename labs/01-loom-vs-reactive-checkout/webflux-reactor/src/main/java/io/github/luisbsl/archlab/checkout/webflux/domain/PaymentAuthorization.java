package io.github.luisbsl.archlab.checkout.webflux.domain;

public record PaymentAuthorization(String authorizationId, String orderId, String status) {}
