package io.github.luisbsl.archlab.checkout.mvc.application.port;

import io.github.luisbsl.archlab.checkout.mvc.domain.InventoryCheck;

public interface InventoryGateway {

  InventoryCheck check(String sku, int quantity);
}
