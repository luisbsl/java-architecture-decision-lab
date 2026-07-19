package io.github.luisbsl.archlab.checkout.mvc.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.net.URI;
import java.time.Duration;
import org.junit.jupiter.api.Test;

class HttpClientConfigTest {

  @Test
  void appliesConfiguredConnectTimeoutToTheJdkHttpClient() {
    var connectTimeout = Duration.ofMillis(350);
    var properties = new CheckoutProperties(
        new CheckoutProperties.Downstream(
            URI.create("http://localhost:8083"),
            connectTimeout,
            Duration.ofSeconds(2)),
        Duration.ofMillis(40),
        Duration.ofMillis(20));

    var httpClient = new HttpClientConfig().simulatorHttpClient(properties);

    assertThat(httpClient.connectTimeout()).contains(connectTimeout);
  }
}
