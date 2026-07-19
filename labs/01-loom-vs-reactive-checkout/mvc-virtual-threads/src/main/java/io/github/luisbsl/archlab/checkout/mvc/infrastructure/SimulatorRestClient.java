package io.github.luisbsl.archlab.checkout.mvc.infrastructure;

import io.github.luisbsl.archlab.checkout.mvc.application.port.CustomerGateway;
import io.github.luisbsl.archlab.checkout.mvc.application.port.InventoryGateway;
import io.github.luisbsl.archlab.checkout.mvc.application.port.PaymentGateway;
import io.github.luisbsl.archlab.checkout.mvc.domain.Customer;
import io.github.luisbsl.archlab.checkout.mvc.domain.InventoryCheck;
import io.github.luisbsl.archlab.checkout.mvc.domain.PaymentAuthorization;
import java.math.BigDecimal;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class SimulatorRestClient implements CustomerGateway, InventoryGateway, PaymentGateway {

  private final RestClient restClient;

  public SimulatorRestClient(
      @Qualifier("simulatorHttpRestClient") RestClient restClient) {
    this.restClient = restClient;
  }

  @Override
  public Customer findById(String customerId) {
    var response = restClient.get()
        .uri("/api/customers/{customerId}", customerId)
        .retrieve()
        .body(CustomerResponse.class);
    requireBody(response, "customer-service");
    return new Customer(response.customerId(), response.status(), response.segment());
  }

  @Override
  public InventoryCheck check(String sku, int quantity) {
    var response = restClient.get()
        .uri(uri -> uri.path("/api/inventory/{sku}")
            .queryParam("quantity", quantity)
            .build(sku))
        .retrieve()
        .body(InventoryResponse.class);
    requireBody(response, "inventory-service");
    return new InventoryCheck(
        response.sku(), response.requestedQuantity(), response.availableQuantity(), response.available());
  }

  @Override
  public PaymentAuthorization authorize(
      String orderId, String customerId, BigDecimal amount, String currency) {
    var request = new PaymentRequest(orderId, customerId, amount, currency);
    var response = restClient.post()
        .uri("/api/payments/authorize")
        .body(request)
        .retrieve()
        .body(PaymentResponse.class);
    requireBody(response, "payment-service");
    return new PaymentAuthorization(response.authorizationId(), response.orderId(), response.status());
  }

  private static void requireBody(Object body, String dependency) {
    if (body == null) {
      throw new IllegalStateException("Empty response from " + dependency);
    }
  }

  private record CustomerResponse(String customerId, String status, String segment) {}

  private record InventoryResponse(
      String sku, int requestedQuantity, int availableQuantity, boolean available) {}

  private record PaymentRequest(
      String orderId, String customerId, BigDecimal amount, String currency) {}

  private record PaymentResponse(String authorizationId, String orderId, String status) {}
}
