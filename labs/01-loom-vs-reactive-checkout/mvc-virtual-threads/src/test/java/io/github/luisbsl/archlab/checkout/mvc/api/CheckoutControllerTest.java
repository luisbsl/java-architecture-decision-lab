package io.github.luisbsl.archlab.checkout.mvc.api;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.github.luisbsl.archlab.checkout.mvc.application.CheckoutResult;
import io.github.luisbsl.archlab.checkout.mvc.application.CheckoutUseCase;
import java.math.BigDecimal;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(CheckoutController.class)
class CheckoutControllerTest {

  @Autowired
  private MockMvc mockMvc;

  @MockitoBean
  private CheckoutUseCase checkoutUseCase;

  @Test
  void createsAConfirmedOrder() throws Exception {
    when(checkoutUseCase.checkout(org.mockito.ArgumentMatchers.any()))
        .thenReturn(new CheckoutResult(
            "order-001", "CONFIRMED", "auth-001", new BigDecimal("299.80"),
            "BRL", Instant.parse("2026-07-15T12:00:00Z")));

    mockMvc.perform(post("/orders/checkout")
            .contentType(MediaType.APPLICATION_JSON)
            .content(validRequest()))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.orderId").value("order-001"))
        .andExpect(jsonPath("$.status").value("CONFIRMED"))
        .andExpect(jsonPath("$.authorizationId").value("auth-001"));
  }

  @Test
  void rejectsInvalidInput() throws Exception {
    mockMvc.perform(post("/orders/checkout")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.title").value("Validation failed"));
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
