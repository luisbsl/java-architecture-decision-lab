package io.github.luisbsl.archlab.checkout.webflux.observability;

import java.util.Map;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.ReactiveHealthIndicator;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Component("simulator")
public class SimulatorReactiveHealthIndicator implements ReactiveHealthIndicator {

  private final WebClient webClient;

  public SimulatorReactiveHealthIndicator(WebClient simulatorWebClient) {
    this.webClient = simulatorWebClient;
  }

  @Override
  public Mono<Health> health() {
    return webClient.get()
        .uri("/api/simulator/status")
        .retrieve()
        .bodyToMono(Map.class)
        .map(body -> Health.up().withDetail("response", body).build())
        .onErrorResume(exception -> Mono.just(Health.down(exception).build()));
  }
}
