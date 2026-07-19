package io.github.luisbsl.archlab.checkout.webflux.application.port;

import io.github.luisbsl.archlab.checkout.webflux.domain.InventoryCheck;
import reactor.core.publisher.Mono;

public interface InventoryGateway {

  Mono<InventoryCheck> check(String sku, int quantity);
}
