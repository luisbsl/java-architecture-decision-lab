package io.github.luisbsl.archlab.checkout.mvc.config;

import io.github.luisbsl.archlab.checkout.mvc.observability.CorrelationIdFilter;
import java.net.http.HttpClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class HttpClientConfig {

  @Bean
  HttpClient simulatorHttpClient(CheckoutProperties properties) {
    return HttpClient.newBuilder()
        .connectTimeout(properties.downstream().connectTimeout())
        .build();
  }

  @Bean("simulatorHttpRestClient")
  RestClient simulatorHttpRestClient(
      CheckoutProperties properties,
      HttpClient simulatorHttpClient) {
    var requestFactory = new JdkClientHttpRequestFactory(simulatorHttpClient);
    requestFactory.setReadTimeout(properties.downstream().readTimeout());

    return RestClient.builder()
        .baseUrl(properties.downstream().baseUrl().toString())
        .requestFactory(requestFactory)
        .requestInterceptor((request, body, execution) -> {
          String correlationId = CorrelationIdFilter.current();
          if (correlationId != null) {
            request.getHeaders().set(CorrelationIdFilter.HEADER, correlationId);
          }
          return execution.execute(request, body);
        })
        .build();
  }
}
