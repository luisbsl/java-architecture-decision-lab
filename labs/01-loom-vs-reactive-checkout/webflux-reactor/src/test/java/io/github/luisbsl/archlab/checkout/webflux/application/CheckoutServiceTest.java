package io.github.luisbsl.archlab.checkout.webflux.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import io.github.luisbsl.archlab.checkout.webflux.application.port.CustomerGateway;
import io.github.luisbsl.archlab.checkout.webflux.application.port.InventoryGateway;
import io.github.luisbsl.archlab.checkout.webflux.application.port.OrderConfirmedPublisher;
import io.github.luisbsl.archlab.checkout.webflux.application.port.OrderRepository;
import io.github.luisbsl.archlab.checkout.webflux.application.port.PaymentGateway;
import io.github.luisbsl.archlab.checkout.webflux.domain.ConfirmedOrder;
import io.github.luisbsl.archlab.checkout.webflux.domain.Customer;
import io.github.luisbsl.archlab.checkout.webflux.domain.InactiveCustomerException;
import io.github.luisbsl.archlab.checkout.webflux.domain.InventoryCheck;
import io.github.luisbsl.archlab.checkout.webflux.domain.InventoryUnavailableException;
import io.github.luisbsl.archlab.checkout.webflux.domain.PaymentAuthorization;
import io.github.luisbsl.archlab.checkout.webflux.observability.CheckoutMetrics;
import io.github.luisbsl.archlab.checkout.webflux.observability.CorrelationIdWebFilter;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class CheckoutServiceTest {

  private CustomerGateway customerGateway;
  private InventoryGateway inventoryGateway;
  private PaymentGateway paymentGateway;
  private OrderRepository orderRepository;
  private OrderConfirmedPublisher publisher;
  private CheckoutService service;

  @BeforeEach
  void setUp() {
    customerGateway = mock(CustomerGateway.class);
    inventoryGateway = mock(InventoryGateway.class);
    paymentGateway = mock(PaymentGateway.class);
    orderRepository = mock(OrderRepository.class);
    publisher = mock(OrderConfirmedPublisher.class);
    var metrics = new CheckoutMetrics(new SimpleMeterRegistry());
    service = new CheckoutService(
        customerGateway, inventoryGateway, paymentGateway, orderRepository, publisher, metrics);
  }

  @Test
  void executesTheEquivalentReactiveFlowInOrder() {
    when(customerGateway.findById("customer-001"))
        .thenReturn(Mono.just(new Customer("customer-001", "ACTIVE", "STANDARD")));
    when(inventoryGateway.check("SKU-001", 2))
        .thenReturn(Mono.just(new InventoryCheck("SKU-001", 2, 100, true)));
    when(paymentGateway.authorize(
        "order-001", "customer-001", new BigDecimal("299.80"), "BRL"))
        .thenReturn(Mono.just(new PaymentAuthorization("auth-001", "order-001", "AUTHORIZED")));
    when(orderRepository.save(any(ConfirmedOrder.class))).thenReturn(Mono.empty());
    when(publisher.publish(any(ConfirmedOrder.class))).thenReturn(Mono.empty());

    StepVerifier.create(withCorrelation(service.checkout(command())))
        .assertNext(result -> {
          assertThat(result.status()).isEqualTo("CONFIRMED");
          assertThat(result.authorizationId()).isEqualTo("auth-001");
          assertThat(result.total()).isEqualByComparingTo("299.80");
        })
        .verifyComplete();

    var ordered = inOrder(
        customerGateway, inventoryGateway, paymentGateway, orderRepository, publisher);
    ordered.verify(customerGateway).findById("customer-001");
    ordered.verify(inventoryGateway).check("SKU-001", 2);
    ordered.verify(paymentGateway).authorize(
        "order-001", "customer-001", new BigDecimal("299.80"), "BRL");
    ordered.verify(orderRepository).save(any(ConfirmedOrder.class));
    ordered.verify(publisher).publish(any(ConfirmedOrder.class));
  }

  @Test
  void stopsBeforePaymentWhenInventoryIsUnavailable() {
    when(customerGateway.findById("customer-001"))
        .thenReturn(Mono.just(new Customer("customer-001", "ACTIVE", "STANDARD")));
    when(inventoryGateway.check("SKU-001", 2))
        .thenReturn(Mono.just(new InventoryCheck("SKU-001", 2, 0, false)));

    StepVerifier.create(withCorrelation(service.checkout(command())))
        .expectError(InventoryUnavailableException.class)
        .verify();

    verifyNoInteractions(paymentGateway, orderRepository, publisher);
  }

  @Test
  void stopsBeforeInventoryWhenCustomerIsInactive() {
    when(customerGateway.findById("customer-001"))
        .thenReturn(Mono.just(new Customer("customer-001", "INACTIVE", "STANDARD")));

    StepVerifier.create(withCorrelation(service.checkout(command())))
        .expectError(InactiveCustomerException.class)
        .verify();

    verifyNoInteractions(inventoryGateway, paymentGateway, orderRepository, publisher);
  }

  @Test
  void stopsBeforePersistenceWhenPaymentFails() {
    when(customerGateway.findById("customer-001"))
        .thenReturn(Mono.just(new Customer("customer-001", "ACTIVE", "STANDARD")));
    when(inventoryGateway.check("SKU-001", 2))
        .thenReturn(Mono.just(new InventoryCheck("SKU-001", 2, 100, true)));
    when(paymentGateway.authorize(
        "order-001", "customer-001", new BigDecimal("299.80"), "BRL"))
        .thenReturn(Mono.error(new IllegalStateException("payment unavailable")));

    StepVerifier.create(withCorrelation(service.checkout(command())))
        .expectErrorMessage("payment unavailable")
        .verify();

    verifyNoInteractions(orderRepository, publisher);
  }

  @Test
  void doesNotPublishWhenPersistenceFails() {
    when(customerGateway.findById("customer-001"))
        .thenReturn(Mono.just(new Customer("customer-001", "ACTIVE", "STANDARD")));
    when(inventoryGateway.check("SKU-001", 2))
        .thenReturn(Mono.just(new InventoryCheck("SKU-001", 2, 100, true)));
    when(paymentGateway.authorize(
        "order-001", "customer-001", new BigDecimal("299.80"), "BRL"))
        .thenReturn(Mono.just(new PaymentAuthorization("auth-001", "order-001", "AUTHORIZED")));
    when(orderRepository.save(any(ConfirmedOrder.class)))
        .thenReturn(Mono.error(new IllegalStateException("persistence unavailable")));

    StepVerifier.create(withCorrelation(service.checkout(command())))
        .expectErrorMessage("persistence unavailable")
        .verify();

    verify(publisher, never()).publish(any(ConfirmedOrder.class));
  }

  @Test
  void rejectsAnEmptyPaymentAuthorization() {
    when(customerGateway.findById("customer-001"))
        .thenReturn(Mono.just(new Customer("customer-001", "ACTIVE", "STANDARD")));
    when(inventoryGateway.check("SKU-001", 2))
        .thenReturn(Mono.just(new InventoryCheck("SKU-001", 2, 100, true)));
    when(paymentGateway.authorize(
        "order-001", "customer-001", new BigDecimal("299.80"), "BRL"))
        .thenReturn(Mono.empty());

    StepVerifier.create(withCorrelation(service.checkout(command())))
        .expectErrorSatisfies(error -> assertThat(error)
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Payment gateway returned no authorization"))
        .verify();

    verifyNoInteractions(orderRepository, publisher);
  }

  private static Mono<CheckoutResult> withCorrelation(Mono<CheckoutResult> operation) {
    return operation.contextWrite(
        context -> context.put(CorrelationIdWebFilter.CONTEXT_KEY, "test-correlation"));
  }

  private static CheckoutCommand command() {
    return new CheckoutCommand(
        "order-001",
        "customer-001",
        List.of(new CheckoutItem("SKU-001", 2, new BigDecimal("149.90"))),
        "BRL");
  }
}
