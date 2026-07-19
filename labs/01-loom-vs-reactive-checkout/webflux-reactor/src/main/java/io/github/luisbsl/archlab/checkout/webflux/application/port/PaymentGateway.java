package io.github.luisbsl.archlab.checkout.webflux.application.port;

import io.github.luisbsl.archlab.checkout.webflux.domain.PaymentAuthorization;
import java.math.BigDecimal;
import reactor.core.publisher.Mono;

public interface PaymentGateway {

  Mono<PaymentAuthorization> authorize(
      String orderId, String customerId, BigDecimal amount, String currency);
}
