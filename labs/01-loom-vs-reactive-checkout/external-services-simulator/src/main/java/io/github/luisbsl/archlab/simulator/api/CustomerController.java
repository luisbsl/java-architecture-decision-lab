package io.github.luisbsl.archlab.simulator.api;

import io.github.luisbsl.archlab.simulator.config.SimulatedService;
import io.github.luisbsl.archlab.simulator.core.SimulationEngine;
import java.time.Instant;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {

  private final SimulationEngine simulationEngine;

  public CustomerController(SimulationEngine simulationEngine) {
    this.simulationEngine = simulationEngine;
  }

  @GetMapping("/{customerId}")
  public ResponseEntity<CustomerResponse> findById(
      @PathVariable String customerId,
      @RequestHeader(value = "X-Correlation-Id", required = false) String correlationId) {
    var simulation = simulationEngine.simulate(SimulatedService.CUSTOMER, correlationId);
    var body = new CustomerResponse(
        customerId,
        "ACTIVE",
        "STANDARD",
        simulation.delayMillis(),
        Instant.now());

    return ResponseEntity.ok()
        .header("X-Simulator-Delay-Ms", Long.toString(simulation.delayMillis()))
        .body(body);
  }

  public record CustomerResponse(
      String customerId,
      String status,
      String segment,
      long simulatedDelayMs,
      Instant respondedAt) {}
}
