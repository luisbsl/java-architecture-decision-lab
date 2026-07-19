package io.github.luisbsl.archlab.checkout.mvc.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import java.util.List;

public record CheckoutRequest(
    @NotBlank String orderId,
    @NotBlank String customerId,
    @NotEmpty List<@Valid OrderItemRequest> items,
    @NotBlank @Pattern(regexp = "[A-Z]{3}") String currency) {}
