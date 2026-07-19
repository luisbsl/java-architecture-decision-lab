package io.github.luisbsl.archlab.checkout.webflux.infrastructure;

import io.github.luisbsl.archlab.checkout.webflux.application.port.OrderConfirmedPublisher;
import io.github.luisbsl.archlab.checkout.webflux.config.CheckoutProperties;
import io.github.luisbsl.archlab.checkout.webflux.domain.ConfirmedOrder;
import java.time.Duration;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

@Component
public class DelayedOrderConfirmedPublisher implements OrderConfirmedPublisher {

  private final Duration delay;

  public DelayedOrderConfirmedPublisher(CheckoutProperties properties) {
    this.delay = properties.eventPublicationDelay();
  }

  @Override
  public Mono<Void> publish(ConfirmedOrder order) {
    return Mono.delay(delay).then();
  }
}
