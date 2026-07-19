package io.github.luisbsl.archlab.checkout.webflux.config;

import io.netty.channel.ChannelOption;
import io.github.luisbsl.archlab.checkout.webflux.observability.CorrelationIdWebFilter;
import java.util.concurrent.TimeUnit;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.ClientRequest;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

@Configuration
public class HttpClientConfig {

  @Bean("simulatorHttpWebClient")
  WebClient simulatorHttpWebClient(CheckoutProperties properties) {
    int connectTimeoutMillis = Math.toIntExact(properties.downstream().connectTimeout().toMillis());
    var httpClient = HttpClient.create()
        .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, connectTimeoutMillis)
        .responseTimeout(properties.downstream().readTimeout())
        .doOnConnected(connection -> connection
            .addHandlerLast(new io.netty.handler.timeout.ReadTimeoutHandler(
                properties.downstream().readTimeout().toMillis(), TimeUnit.MILLISECONDS)));

    return WebClient.builder()
        .baseUrl(properties.downstream().baseUrl().toString())
        .clientConnector(new ReactorClientHttpConnector(httpClient))
        .filter((request, next) -> reactor.core.publisher.Mono.deferContextual(context -> {
          String correlationId = context.getOrDefault(
              CorrelationIdWebFilter.CONTEXT_KEY, "unavailable");
          var correlated = ClientRequest.from(request)
              .header(CorrelationIdWebFilter.HEADER, correlationId)
              .build();
          return next.exchange(correlated);
        }))
        .build();
  }
}
