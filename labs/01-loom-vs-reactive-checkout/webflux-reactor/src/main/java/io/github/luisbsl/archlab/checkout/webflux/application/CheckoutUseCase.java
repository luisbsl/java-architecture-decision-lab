package io.github.luisbsl.archlab.checkout.webflux.application;

import reactor.core.publisher.Mono;

public interface CheckoutUseCase {

  Mono<CheckoutResult> checkout(CheckoutCommand command);
}
