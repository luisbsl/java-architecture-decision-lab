package io.github.luisbsl.archlab.checkout.webflux.infrastructure;

import io.github.luisbsl.archlab.checkout.webflux.application.port.OrderRepository;
import io.github.luisbsl.archlab.checkout.webflux.config.CheckoutProperties;
import io.github.luisbsl.archlab.checkout.webflux.domain.ConfirmedOrder;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

@Repository
public class InMemoryOrderRepository implements OrderRepository {

  private final Map<String, ConfirmedOrder> orders = new ConcurrentHashMap<>();
  private final Duration delay;

  public InMemoryOrderRepository(CheckoutProperties properties) {
    this.delay = properties.persistenceDelay();
  }

  @Override
  public Mono<Void> save(ConfirmedOrder order) {
    return Mono.delay(delay)
        .doOnNext(ignored -> orders.put(order.orderId(), order))
        .then();
  }
}
