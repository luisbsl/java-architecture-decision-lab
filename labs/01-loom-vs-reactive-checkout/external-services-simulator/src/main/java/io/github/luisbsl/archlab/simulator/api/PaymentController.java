package io.github.luisbsl.archlab.simulator.api;

import io.github.luisbsl.archlab.simulator.config.SimulatedService;
import io.github.luisbsl.archlab.simulator.core.SimulationEngine;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.math.BigDecimal;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

  private final SimulationEngine simulationEngine;

  public PaymentController(SimulationEngine simulationEngine) {
    this.simulationEngine = simulationEngine;
  }

  @PostMapping("/authorize")
  public ResponseEntity<PaymentAuthorizationResponse> authorize(
      @Valid @RequestBody PaymentAuthorizationRequest request,
      @RequestHeader(value = "X-Correlation-Id", required = false) String correlationId) {

    var simulation = simulationEngine.simulate(SimulatedService.PAYMENT, correlationId);
    var body = new PaymentAuthorizationResponse(
        UUID.randomUUID().toString(),
        request.orderId(),
        "AUTHORIZED",
        request.amount(),
        request.currency(),
        simulation.delayMillis());

    return ResponseEntity.ok()
        .header("X-Simulator-Delay-Ms", Long.toString(simulation.delayMillis()))
        .body(body);
  }

  public record PaymentAuthorizationRequest(
      @NotBlank String orderId,
      @NotBlank String customerId,
      @NotNull @DecimalMin(value = "0.01") BigDecimal amount,
      @NotBlank @Pattern(regexp = "[A-Z]{3}") String currency) {}

  public record PaymentAuthorizationResponse(
      String authorizationId,
      String orderId,
      String status,
      BigDecimal amount,
      String currency,
      long simulatedDelayMs) {}
}
