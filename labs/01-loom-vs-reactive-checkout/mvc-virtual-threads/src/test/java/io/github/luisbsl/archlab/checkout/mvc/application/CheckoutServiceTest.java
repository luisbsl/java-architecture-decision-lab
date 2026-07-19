package io.github.luisbsl.archlab.checkout.mvc.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.github.luisbsl.archlab.checkout.mvc.application.port.CustomerGateway;
import io.github.luisbsl.archlab.checkout.mvc.application.port.InventoryGateway;
import io.github.luisbsl.archlab.checkout.mvc.application.port.OrderConfirmedPublisher;
import io.github.luisbsl.archlab.checkout.mvc.application.port.OrderRepository;
import io.github.luisbsl.archlab.checkout.mvc.application.port.PaymentGateway;
import io.github.luisbsl.archlab.checkout.mvc.domain.Customer;
import io.github.luisbsl.archlab.checkout.mvc.domain.InventoryCheck;
import io.github.luisbsl.archlab.checkout.mvc.domain.InventoryUnavailableException;
import io.github.luisbsl.archlab.checkout.mvc.domain.PaymentAuthorization;
import io.github.luisbsl.archlab.checkout.mvc.observability.CheckoutMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class CheckoutServiceTest {

  private CustomerGateway customerGateway;
  private InventoryGateway inventoryGateway;
  private PaymentGateway paymentGateway;
  private OrderRepository orderRepository;
  private OrderConfirmedPublisher publisher;
  private CheckoutService service;
  private CheckoutMetrics metrics;

  @BeforeEach
  void setUp() {
    customerGateway = mock(CustomerGateway.class);
    inventoryGateway = mock(InventoryGateway.class);
    paymentGateway = mock(PaymentGateway.class);
    orderRepository = mock(OrderRepository.class);
    publisher = mock(OrderConfirmedPublisher.class);
    metrics = new CheckoutMetrics(new SimpleMeterRegistry());
    service = new CheckoutService(
        customerGateway, inventoryGateway, paymentGateway, orderRepository, publisher, metrics);
  }

  @Test
  void executesTheSequentialCheckoutFlow() {
    var command = command();
    when(customerGateway.findById("customer-001"))
        .thenReturn(new Customer("customer-001", "ACTIVE", "STANDARD"));
    when(inventoryGateway.check("SKU-001", 2))
        .thenReturn(new InventoryCheck("SKU-001", 2, 100, true));
    when(paymentGateway.authorize(
        "order-001", "customer-001", new BigDecimal("299.80"), "BRL"))
        .thenReturn(new PaymentAuthorization("auth-001", "order-001", "AUTHORIZED"));

    var result = service.checkout(command);

    assertThat(result.status()).isEqualTo("CONFIRMED");
    assertThat(result.authorizationId()).isEqualTo("auth-001");
    assertThat(result.total()).isEqualByComparingTo("299.80");

    var ordered = inOrder(
        customerGateway, inventoryGateway, paymentGateway, orderRepository, publisher);
    ordered.verify(customerGateway).findById("customer-001");
    ordered.verify(inventoryGateway).check("SKU-001", 2);
    ordered.verify(paymentGateway).authorize(
        "order-001", "customer-001", new BigDecimal("299.80"), "BRL");
    ordered.verify(orderRepository).save(org.mockito.ArgumentMatchers.any());
    ordered.verify(publisher).publish(org.mockito.ArgumentMatchers.any());
  }

  @Test
  void stopsBeforePaymentWhenInventoryIsUnavailable() {
    when(customerGateway.findById("customer-001"))
        .thenReturn(new Customer("customer-001", "ACTIVE", "STANDARD"));
    when(inventoryGateway.check("SKU-001", 2))
        .thenReturn(new InventoryCheck("SKU-001", 2, 0, false));

    assertThatThrownBy(() -> service.checkout(command()))
        .isInstanceOf(InventoryUnavailableException.class);

    verify(paymentGateway, never()).authorize(
        org.mockito.ArgumentMatchers.anyString(),
        org.mockito.ArgumentMatchers.anyString(),
        org.mockito.ArgumentMatchers.any(),
        org.mockito.ArgumentMatchers.anyString());
  }

  private static CheckoutCommand command() {
    return new CheckoutCommand(
        "order-001",
        "customer-001",
        List.of(new CheckoutItem("SKU-001", 2, new BigDecimal("149.90"))),
        "BRL");
  }
}
