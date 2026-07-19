package io.github.luisbsl.archlab.checkout.webflux.api;

import static org.mockito.Mockito.when;

import io.github.luisbsl.archlab.checkout.webflux.application.CheckoutResult;
import io.github.luisbsl.archlab.checkout.webflux.application.CheckoutUseCase;
import java.math.BigDecimal;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.WebFluxTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.core.publisher.Mono;

@WebFluxTest(CheckoutController.class)
class CheckoutControllerTest {

  @Autowired
  private WebTestClient webTestClient;

  @MockitoBean
  private CheckoutUseCase checkoutUseCase;

  @Test
  void createsAConfirmedOrder() {
    when(checkoutUseCase.checkout(org.mockito.ArgumentMatchers.any()))
        .thenReturn(Mono.just(new CheckoutResult(
            "order-001", "CONFIRMED", "auth-001", new BigDecimal("299.80"),
            "BRL", Instant.parse("2026-07-15T12:00:00Z"))));

    webTestClient.post()
        .uri("/orders/checkout")
        .contentType(MediaType.APPLICATION_JSON)
        .bodyValue(validRequest())
        .exchange()
        .expectStatus().isCreated()
        .expectBody()
        .jsonPath("$.orderId").isEqualTo("order-001")
        .jsonPath("$.status").isEqualTo("CONFIRMED")
        .jsonPath("$.authorizationId").isEqualTo("auth-001");
  }

  @Test
  void rejectsInvalidInput() {
    webTestClient.post()
        .uri("/orders/checkout")
        .contentType(MediaType.APPLICATION_JSON)
        .bodyValue("{}")
        .exchange()
        .expectStatus().isBadRequest();
  }

  private static String validRequest() {
    return """
        {
          "orderId": "order-001",
          "customerId": "customer-001",
          "items": [
            {"sku": "SKU-001", "quantity": 2, "unitPrice": 149.90}
          ],
          "currency": "BRL"
        }
        """;
  }
}
