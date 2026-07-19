package io.github.luisbsl.archlab.checkout.mvc.config;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.net.URI;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties("checkout")
public record CheckoutProperties(
    @Valid @NotNull Downstream downstream,
    @NotNull Duration persistenceDelay,
    @NotNull Duration eventPublicationDelay) {

  public record Downstream(
      @NotNull URI baseUrl,
      @NotNull Duration connectTimeout,
      @NotNull Duration readTimeout) {}
}
