package io.github.luisbsl.archlab.checkout.mvc;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.luisbsl.archlab.checkout.mvc.infrastructure.SimulatorRestClient;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.web.client.RestClient;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class MvcVirtualThreadsApplicationTests {

  @Autowired
  private ApplicationContext context;

  @Test
  void startsWithExactlyOneSimulatorAdapterAndOneTransportClient() {
    assertThat(context.getBeansOfType(SimulatorRestClient.class))
        .containsOnlyKeys("simulatorRestClient");
    assertThat(context.getBeansOfType(RestClient.class))
        .containsOnlyKeys("simulatorHttpRestClient");
  }
}
