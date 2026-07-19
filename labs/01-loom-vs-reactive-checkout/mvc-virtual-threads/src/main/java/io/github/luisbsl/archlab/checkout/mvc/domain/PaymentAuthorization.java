package io.github.luisbsl.archlab.checkout.mvc.domain;

public record PaymentAuthorization(String authorizationId, String orderId, String status) {}
