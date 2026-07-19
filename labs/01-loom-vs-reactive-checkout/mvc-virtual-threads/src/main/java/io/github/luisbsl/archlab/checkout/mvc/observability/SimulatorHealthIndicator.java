package io.github.luisbsl.archlab.checkout.mvc.observability;

import java.util.Map;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component("simulator")
public class SimulatorHealthIndicator implements HealthIndicator {

  private final RestClient restClient;

  public SimulatorHealthIndicator(RestClient simulatorRestClient) {
    this.restClient = simulatorRestClient;
  }

  @Override
  public Health health() {
    try {
      Map<?, ?> body = restClient.get()
          .uri("/api/simulator/status")
          .retrieve()
          .body(Map.class);
      return Health.up().withDetail("response", body == null ? Map.of() : body).build();
    } catch (RuntimeException exception) {
      return Health.down(exception).build();
    }
  }
}
