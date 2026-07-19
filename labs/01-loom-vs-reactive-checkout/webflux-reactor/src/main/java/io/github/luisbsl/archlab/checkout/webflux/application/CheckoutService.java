package io.github.luisbsl.archlab.checkout.webflux.application;

import io.github.luisbsl.archlab.checkout.webflux.application.port.CustomerGateway;
import io.github.luisbsl.archlab.checkout.webflux.application.port.InventoryGateway;
import io.github.luisbsl.archlab.checkout.webflux.application.port.OrderConfirmedPublisher;
import io.github.luisbsl.archlab.checkout.webflux.application.port.OrderRepository;
import io.github.luisbsl.archlab.checkout.webflux.application.port.PaymentGateway;
import io.github.luisbsl.archlab.checkout.webflux.domain.ConfirmedOrder;
import io.github.luisbsl.archlab.checkout.webflux.domain.InactiveCustomerException;
import io.github.luisbsl.archlab.checkout.webflux.domain.InventoryUnavailableException;
import io.github.luisbsl.archlab.checkout.webflux.observability.CheckoutMetrics;
import io.github.luisbsl.archlab.checkout.webflux.observability.CorrelationIdWebFilter;
import java.math.BigDecimal;
import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

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
  public Mono<CheckoutResult> checkout(CheckoutCommand command) {
    return Mono.deferContextual(context -> {
      String correlationId = context.getOrDefault(
          CorrelationIdWebFilter.CONTEXT_KEY, "unavailable");
      log.atDebug()
          .addKeyValue("correlationId", correlationId)
          .addKeyValue("orderId", command.orderId())
          .addKeyValue("implementation", "webflux-reactor")
          .log("Checkout started");
      return metrics.record(execute(command))
          .doOnNext(result -> log.atDebug()
              .addKeyValue("correlationId", correlationId)
              .addKeyValue("orderId", result.orderId())
              .addKeyValue("implementation", "webflux-reactor")
              .log("Checkout confirmed"));
    });
  }

  private Mono<CheckoutResult> execute(CheckoutCommand command) {
    BigDecimal total = command.items().stream()
        .map(CheckoutItem::subtotal)
        .reduce(BigDecimal.ZERO, BigDecimal::add);

    return Mono.defer(() -> customerGateway.findById(command.customerId()))
        .switchIfEmpty(Mono.error(new IllegalStateException(
            "Customer gateway returned no customer for " + command.customerId())))
        .flatMap(customer -> customer.active()
            ? verifyInventory(command)
            : Mono.error(new InactiveCustomerException(command.customerId())))
        .then(Mono.defer(() -> paymentGateway.authorize(
            command.orderId(), command.customerId(), total, command.currency())))
        .switchIfEmpty(Mono.error(new IllegalStateException(
            "Payment gateway returned no authorization for " + command.orderId())))
        .map(authorization -> new ConfirmedOrder(
            command.orderId(), command.customerId(), total, command.currency(),
            authorization.authorizationId(), Instant.now()))
        .flatMap(order -> Mono.defer(() -> orderRepository.save(order))
            .then(Mono.defer(() -> orderConfirmedPublisher.publish(order)))
            .thenReturn(order))
        .map(order -> new CheckoutResult(
            order.orderId(), "CONFIRMED", order.authorizationId(), order.total(),
            order.currency(), order.confirmedAt()));
  }

  private Mono<Void> verifyInventory(CheckoutCommand command) {
    return Flux.fromIterable(command.items())
        .concatMap(item -> Mono.defer(() -> inventoryGateway.check(item.sku(), item.quantity()))
            .switchIfEmpty(Mono.error(new IllegalStateException(
                "Inventory gateway returned no result for " + item.sku())))
            .flatMap(check -> check.available()
                ? Mono.empty()
                : Mono.error(new InventoryUnavailableException(item.sku(), item.quantity()))))
        .then();
  }
}
