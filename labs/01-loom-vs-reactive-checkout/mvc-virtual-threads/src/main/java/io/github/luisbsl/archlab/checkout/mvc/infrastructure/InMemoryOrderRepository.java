package io.github.luisbsl.archlab.checkout.mvc.infrastructure;

import io.github.luisbsl.archlab.checkout.mvc.application.port.OrderRepository;
import io.github.luisbsl.archlab.checkout.mvc.config.CheckoutProperties;
import io.github.luisbsl.archlab.checkout.mvc.domain.ConfirmedOrder;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Repository;

@Repository
public class InMemoryOrderRepository implements OrderRepository {

  private final Map<String, ConfirmedOrder> orders = new ConcurrentHashMap<>();
  private final Duration delay;

  public InMemoryOrderRepository(CheckoutProperties properties) {
    this.delay = properties.persistenceDelay();
  }

  @Override
  public void save(ConfirmedOrder order) {
    ControlledDelay.sleep(delay);
    orders.put(order.orderId(), order);
  }
}
