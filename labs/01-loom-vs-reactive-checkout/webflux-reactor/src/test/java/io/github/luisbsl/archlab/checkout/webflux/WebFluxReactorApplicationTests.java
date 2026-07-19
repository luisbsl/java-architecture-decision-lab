package io.github.luisbsl.archlab.checkout.webflux;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.luisbsl.archlab.checkout.webflux.infrastructure.SimulatorWebClient;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.web.reactive.function.client.WebClient;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class WebFluxReactorApplicationTests {

  @Autowired
  private ApplicationContext context;

  @Test
  void startsWithExactlyOneSimulatorAdapterAndOneTransportClient() {
    assertThat(context.getBeansOfType(SimulatorWebClient.class))
        .containsOnlyKeys("simulatorWebClient");
    assertThat(context.getBeansOfType(WebClient.class))
        .containsOnlyKeys("simulatorHttpWebClient");
  }
}
