package io.github.luisbsl.archlab.checkout.webflux.application.port;

import io.github.luisbsl.archlab.checkout.webflux.domain.Customer;
import reactor.core.publisher.Mono;

public interface CustomerGateway {

  Mono<Customer> findById(String customerId);
}
