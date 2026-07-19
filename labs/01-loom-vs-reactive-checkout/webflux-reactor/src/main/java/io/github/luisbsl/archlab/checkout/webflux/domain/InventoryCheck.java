package io.github.luisbsl.archlab.checkout.webflux.domain;

public record InventoryCheck(
    String sku, int requestedQuantity, int availableQuantity, boolean available) {}
