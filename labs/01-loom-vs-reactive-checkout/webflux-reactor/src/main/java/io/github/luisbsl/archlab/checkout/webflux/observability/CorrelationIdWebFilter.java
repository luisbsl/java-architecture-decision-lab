package io.github.luisbsl.archlab.checkout.webflux.observability;

import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

@Component
public class CorrelationIdWebFilter implements WebFilter {

  public static final String HEADER = "X-Correlation-Id";
  public static final String CONTEXT_KEY = "correlationId";

  @Override
  public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
    String correlationId = resolve(exchange.getRequest().getHeaders().getFirst(HEADER));
    exchange.getResponse().getHeaders().set(HEADER, correlationId);
    var request = exchange.getRequest().mutate().header(HEADER, correlationId).build();
    return chain.filter(exchange.mutate().request(request).build())
        .contextWrite(context -> context.put(CONTEXT_KEY, correlationId));
  }

  private static String resolve(String candidate) {
    return StringUtils.hasText(candidate) ? candidate : UUID.randomUUID().toString();
  }
}
