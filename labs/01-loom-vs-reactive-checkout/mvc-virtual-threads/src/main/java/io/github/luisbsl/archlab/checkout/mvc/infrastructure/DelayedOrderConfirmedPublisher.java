package io.github.luisbsl.archlab.checkout.mvc.infrastructure;

import io.github.luisbsl.archlab.checkout.mvc.application.port.OrderConfirmedPublisher;
import io.github.luisbsl.archlab.checkout.mvc.config.CheckoutProperties;
import io.github.luisbsl.archlab.checkout.mvc.domain.ConfirmedOrder;
import java.time.Duration;
import org.springframework.stereotype.Component;

@Component
public class DelayedOrderConfirmedPublisher implements OrderConfirmedPublisher {

  private final Duration delay;

  public DelayedOrderConfirmedPublisher(CheckoutProperties properties) {
    this.delay = properties.eventPublicationDelay();
  }

  @Override
  public void publish(ConfirmedOrder order) {
    ControlledDelay.sleep(delay);
  }
}
