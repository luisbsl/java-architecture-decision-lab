package io.github.luisbsl.archlab.checkout.webflux.observability;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.luisbsl.archlab.checkout.webflux.application.CheckoutResult;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.math.BigDecimal;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class CheckoutMetricsTest {

  private SimpleMeterRegistry registry;
  private CheckoutMetrics metrics;

  @BeforeEach
  void setUp() {
    registry = new SimpleMeterRegistry();
    metrics = new CheckoutMetrics(registry);
  }

  @Test
  void recordsExactlyOneCompletedCheckoutForOneResult() {
    StepVerifier.create(metrics.record(Mono.just(result())))
        .expectNext(result())
        .verifyComplete();

    assertThat(counter("checkout.completed")).isEqualTo(1.0);
    assertThat(counter("checkout.failed")).isZero();
  }

  @Test
  void recordsFailuresWithoutMarkingTheCheckoutAsCompleted() {
    StepVerifier.create(metrics.record(Mono.error(new IllegalStateException("boom"))))
        .expectErrorMessage("boom")
        .verify();

    assertThat(counter("checkout.completed")).isZero();
    assertThat(counter("checkout.failed")).isEqualTo(1.0);
  }

  @Test
  void doesNotTreatAnEmptyPublisherAsACompletedCheckout() {
    StepVerifier.create(metrics.record(Mono.empty()))
        .verifyComplete();

    assertThat(counter("checkout.completed")).isZero();
    assertThat(counter("checkout.failed")).isZero();
  }

  private double counter(String name) {
    return registry.get(name)
        .tag("implementation", "webflux-reactor")
        .counter()
        .count();
  }

  private static CheckoutResult result() {
    return new CheckoutResult(
        "order-001",
        "CONFIRMED",
        "auth-001",
        new BigDecimal("299.80"),
        "BRL",
        Instant.parse("2026-07-17T18:00:00Z"));
  }
}
