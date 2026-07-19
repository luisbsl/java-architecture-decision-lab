package io.github.luisbsl.archlab.checkout.webflux.application;

import java.math.BigDecimal;

public record CheckoutItem(String sku, int quantity, BigDecimal unitPrice) {

  public BigDecimal subtotal() {
    return unitPrice.multiply(BigDecimal.valueOf(quantity));
  }
}
