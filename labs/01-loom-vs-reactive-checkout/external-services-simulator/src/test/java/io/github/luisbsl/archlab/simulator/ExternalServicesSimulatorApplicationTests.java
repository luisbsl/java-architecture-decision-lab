package io.github.luisbsl.archlab.simulator;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = {
    "simulator.customer.min-delay=0ms",
    "simulator.customer.max-delay=0ms",
    "simulator.customer.failure-rate=0.0",
    "simulator.inventory.min-delay=0ms",
    "simulator.inventory.max-delay=0ms",
    "simulator.inventory.failure-rate=0.0",
    "simulator.payment.min-delay=0ms",
    "simulator.payment.max-delay=0ms",
    "simulator.payment.failure-rate=0.0"
})
@AutoConfigureMockMvc
class ExternalServicesSimulatorApplicationTests {

  @Autowired
  private MockMvc mockMvc;

  @Test
  void exposesSimulatorStatus() throws Exception {
    mockMvc.perform(get("/api/simulator/status"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("UP"))
        .andExpect(jsonPath("$.dependencies", hasSize(3)));
  }

  @Test
  void returnsCustomerData() throws Exception {
    mockMvc.perform(get("/api/customers/customer-001"))
        .andExpect(status().isOk())
        .andExpect(header().string("X-Simulator-Delay-Ms", "0"))
        .andExpect(jsonPath("$.customerId").value("customer-001"))
        .andExpect(jsonPath("$.status").value("ACTIVE"));
  }

  @Test
  void returnsInventoryAvailability() throws Exception {
    mockMvc.perform(get("/api/inventory/SKU-001").param("quantity", "2"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.sku").value("SKU-001"))
        .andExpect(jsonPath("$.requestedQuantity").value(2))
        .andExpect(jsonPath("$.available").value(true));
  }

  @Test
  void authorizesPayment() throws Exception {
    String request = """
        {
          "orderId": "order-001",
          "customerId": "customer-001",
          "amount": 149.90,
          "currency": "BRL"
        }
        """;

    mockMvc.perform(post("/api/payments/authorize")
            .contentType(MediaType.APPLICATION_JSON)
            .content(request))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.orderId").value("order-001"))
        .andExpect(jsonPath("$.status").value("AUTHORIZED"))
        .andExpect(jsonPath("$.amount", equalTo(149.9)))
        .andExpect(jsonPath("$.currency").value("BRL"));
  }

  @Test
  void rejectsInvalidInventoryQuantity() throws Exception {
    mockMvc.perform(get("/api/inventory/SKU-001").param("quantity", "0"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.title").value("Validation failed"));
  }

  @Test
  void rejectsInvalidPayment() throws Exception {
    String request = """
        {
          "orderId": "",
          "customerId": "customer-001",
          "amount": 0,
          "currency": "brl"
        }
        """;

    mockMvc.perform(post("/api/payments/authorize")
            .contentType(MediaType.APPLICATION_JSON)
            .content(request))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.title").value("Validation failed"));
  }
}
