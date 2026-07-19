package io.github.luisbsl.archlab.simulator.api;

import io.github.luisbsl.archlab.simulator.config.SimulatedService;
import io.github.luisbsl.archlab.simulator.core.SimulationEngine;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/inventory")
public class InventoryController {

  private static final int BASE_AVAILABLE_QUANTITY = 100;

  private final SimulationEngine simulationEngine;

  public InventoryController(SimulationEngine simulationEngine) {
    this.simulationEngine = simulationEngine;
  }

  @GetMapping("/{sku}")
  public ResponseEntity<InventoryResponse> check(
      @PathVariable String sku,
      @RequestParam(defaultValue = "1") @Min(1) int quantity,
      @RequestHeader(value = "X-Correlation-Id", required = false) String correlationId) {

    var simulation = simulationEngine.simulate(SimulatedService.INVENTORY, correlationId);
    boolean available = quantity <= BASE_AVAILABLE_QUANTITY;
    var body = new InventoryResponse(
        sku,
        quantity,
        BASE_AVAILABLE_QUANTITY,
        available,
        simulation.delayMillis());

    return ResponseEntity.ok()
        .header("X-Simulator-Delay-Ms", Long.toString(simulation.delayMillis()))
        .body(body);
  }

  public record InventoryResponse(
      String sku,
      int requestedQuantity,
      int availableQuantity,
      boolean available,
      long simulatedDelayMs) {}
}
