package io.github.luisbsl.archlab.simulator.api;

import java.time.Instant;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/simulator")
public class SimulatorStatusController {

  @GetMapping("/status")
  public SimulatorStatus status() {
    return new SimulatorStatus(
        "UP",
        List.of("customer-service", "inventory-service", "payment-service"),
        Instant.now());
  }

  public record SimulatorStatus(String status, List<String> dependencies, Instant respondedAt) {}
}
