package io.github.luisbsl.archlab.checkout.webflux.domain;

public class InventoryUnavailableException extends RuntimeException {

  private final String sku;

  public InventoryUnavailableException(String sku, int requestedQuantity) {
    super("Inventory is unavailable for SKU %s and quantity %d".formatted(sku, requestedQuantity));
    this.sku = sku;
  }

  public String sku() {
    return sku;
  }
}
