package io.github.luisbsl.archlab.checkout.webflux.infrastructure;

import io.github.luisbsl.archlab.checkout.webflux.application.port.CustomerGateway;
import io.github.luisbsl.archlab.checkout.webflux.application.port.InventoryGateway;
import io.github.luisbsl.archlab.checkout.webflux.application.port.PaymentGateway;
import io.github.luisbsl.archlab.checkout.webflux.domain.Customer;
import io.github.luisbsl.archlab.checkout.webflux.domain.InventoryCheck;
import io.github.luisbsl.archlab.checkout.webflux.domain.PaymentAuthorization;
import java.math.BigDecimal;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Component
public class SimulatorWebClient implements CustomerGateway, InventoryGateway, PaymentGateway {

  private final WebClient webClient;

  public SimulatorWebClient(
      @Qualifier("simulatorHttpWebClient") WebClient webClient) {
    this.webClient = webClient;
  }

  @Override
  public Mono<Customer> findById(String customerId) {
    return webClient.get()
        .uri("/api/customers/{customerId}", customerId)
        .retrieve()
        .bodyToMono(CustomerResponse.class)
        .switchIfEmpty(Mono.error(new IllegalStateException("Empty response from customer-service")))
        .map(response -> new Customer(response.customerId(), response.status(), response.segment()));
  }

  @Override
  public Mono<InventoryCheck> check(String sku, int quantity) {
    return webClient.get()
        .uri(uri -> uri.path("/api/inventory/{sku}")
            .queryParam("quantity", quantity)
            .build(sku))
        .retrieve()
        .bodyToMono(InventoryResponse.class)
        .switchIfEmpty(Mono.error(new IllegalStateException("Empty response from inventory-service")))
        .map(response -> new InventoryCheck(
            response.sku(), response.requestedQuantity(), response.availableQuantity(),
            response.available()));
  }

  @Override
  public Mono<PaymentAuthorization> authorize(
      String orderId, String customerId, BigDecimal amount, String currency) {
    return webClient.post()
        .uri("/api/payments/authorize")
        .bodyValue(new PaymentRequest(orderId, customerId, amount, currency))
        .retrieve()
        .bodyToMono(PaymentResponse.class)
        .switchIfEmpty(Mono.error(new IllegalStateException("Empty response from payment-service")))
        .map(response -> new PaymentAuthorization(
            response.authorizationId(), response.orderId(), response.status()));
  }

  private record CustomerResponse(String customerId, String status, String segment) {}

  private record InventoryResponse(
      String sku, int requestedQuantity, int availableQuantity, boolean available) {}

  private record PaymentRequest(
      String orderId, String customerId, BigDecimal amount, String currency) {}

  private record PaymentResponse(String authorizationId, String orderId, String status) {}
}
