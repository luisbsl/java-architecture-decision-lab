package io.github.luisbsl.archlab.checkout.mvc.application;

import io.github.luisbsl.archlab.checkout.mvc.application.port.CustomerGateway;
import io.github.luisbsl.archlab.checkout.mvc.application.port.InventoryGateway;
import io.github.luisbsl.archlab.checkout.mvc.application.port.OrderConfirmedPublisher;
import io.github.luisbsl.archlab.checkout.mvc.application.port.OrderRepository;
import io.github.luisbsl.archlab.checkout.mvc.application.port.PaymentGateway;
import io.github.luisbsl.archlab.checkout.mvc.domain.ConfirmedOrder;
import io.github.luisbsl.archlab.checkout.mvc.domain.InactiveCustomerException;
import io.github.luisbsl.archlab.checkout.mvc.domain.InventoryUnavailableException;
import java.math.BigDecimal;
import java.time.Instant;
import io.github.luisbsl.archlab.checkout.mvc.observability.CheckoutMetrics;
import io.github.luisbsl.archlab.checkout.mvc.observability.CorrelationIdFilter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class CheckoutService implements CheckoutUseCase {

  private static final Logger log = LoggerFactory.getLogger(CheckoutService.class);

  private final CustomerGateway customerGateway;
  private final InventoryGateway inventoryGateway;
  private final PaymentGateway paymentGateway;
  private final OrderRepository orderRepository;
  private final OrderConfirmedPublisher orderConfirmedPublisher;
  private final CheckoutMetrics metrics;

  public CheckoutService(
      CustomerGateway customerGateway,
      InventoryGateway inventoryGateway,
      PaymentGateway paymentGateway,
      OrderRepository orderRepository,
      OrderConfirmedPublisher orderConfirmedPublisher,
      CheckoutMetrics metrics) {
    this.customerGateway = customerGateway;
    this.inventoryGateway = inventoryGateway;
    this.paymentGateway = paymentGateway;
    this.orderRepository = orderRepository;
    this.orderConfirmedPublisher = orderConfirmedPublisher;
    this.metrics = metrics;
  }

  @Override
  public CheckoutResult checkout(CheckoutCommand command) {
    return metrics.record(() -> execute(command));
  }

  private CheckoutResult execute(CheckoutCommand command) {
    log.atDebug()
        .addKeyValue("correlationId", CorrelationIdFilter.current())
        .addKeyValue("orderId", command.orderId())
        .addKeyValue("implementation", "mvc-vthreads")
        .log("Checkout started");

    var customer = customerGateway.findById(command.customerId());
    if (!customer.active()) {
      throw new InactiveCustomerException(command.customerId());
    }

    for (var item : command.items()) {
      var inventory = inventoryGateway.check(item.sku(), item.quantity());
      if (!inventory.available()) {
        throw new InventoryUnavailableException(item.sku(), item.quantity());
      }
    }

    BigDecimal total = command.items().stream()
        .map(CheckoutItem::subtotal)
        .reduce(BigDecimal.ZERO, BigDecimal::add);

    var authorization = paymentGateway.authorize(
        command.orderId(), command.customerId(), total, command.currency());
    var processedAt = Instant.now();
    var order = new ConfirmedOrder(
        command.orderId(), command.customerId(), total, command.currency(),
        authorization.authorizationId(), processedAt);

    orderRepository.save(order);
    orderConfirmedPublisher.publish(order);

    var result = new CheckoutResult(
        order.orderId(), "CONFIRMED", order.authorizationId(), order.total(),
        order.currency(), order.confirmedAt());
    log.atDebug()
        .addKeyValue("correlationId", CorrelationIdFilter.current())
        .addKeyValue("orderId", result.orderId())
        .addKeyValue("implementation", "mvc-vthreads")
        .log("Checkout confirmed");
    return result;
  }
}
