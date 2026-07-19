package io.github.luisbsl.archlab.simulator.observability;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class CorrelationIdFilter extends OncePerRequestFilter {

  public static final String HEADER = "X-Correlation-Id";

  @Override
  protected void doFilterInternal(
      HttpServletRequest request,
      HttpServletResponse response,
      FilterChain filterChain) throws ServletException, IOException {
    String incoming = request.getHeader(HEADER);
    String correlationId = StringUtils.hasText(incoming) ? incoming : UUID.randomUUID().toString();
    response.setHeader(HEADER, correlationId);
    MDC.put("correlationId", correlationId);
    try {
      filterChain.doFilter(request, response);
    } finally {
      MDC.remove("correlationId");
    }
  }
}
