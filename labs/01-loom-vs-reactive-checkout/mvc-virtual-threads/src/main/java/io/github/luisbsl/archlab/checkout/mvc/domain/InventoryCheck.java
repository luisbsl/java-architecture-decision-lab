package io.github.luisbsl.archlab.checkout.mvc.domain;

public record InventoryCheck(
    String sku, int requestedQuantity, int availableQuantity, boolean available) {}
