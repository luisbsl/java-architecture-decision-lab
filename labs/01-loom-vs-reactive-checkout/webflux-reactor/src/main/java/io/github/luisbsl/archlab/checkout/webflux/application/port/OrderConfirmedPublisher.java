package io.github.luisbsl.archlab.checkout.webflux.application.port;

import io.github.luisbsl.archlab.checkout.webflux.domain.ConfirmedOrder;
import reactor.core.publisher.Mono;

public interface OrderConfirmedPublisher {

  Mono<Void> publish(ConfirmedOrder order);
}
