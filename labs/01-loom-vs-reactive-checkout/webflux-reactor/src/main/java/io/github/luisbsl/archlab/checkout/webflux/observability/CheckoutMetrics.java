package io.github.luisbsl.archlab.checkout.webflux.observability;

import io.github.luisbsl.archlab.checkout.webflux.application.CheckoutResult;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

@Component
public class CheckoutMetrics {

  private final Counter completed;
  private final Counter failed;
  private final Timer duration;
  private final MeterRegistry registry;

  public CheckoutMetrics(MeterRegistry registry) {
    this.registry = registry;
    this.completed = Counter.builder("checkout.completed")
        .description("Successfully confirmed checkouts")
        .tag("implementation", "webflux-reactor")
        .register(registry);
    this.failed = Counter.builder("checkout.failed")
        .description("Checkout failures")
        .tag("implementation", "webflux-reactor")
        .register(registry);
    this.duration = Timer.builder("checkout.duration")
        .description("End-to-end checkout duration")
        .tag("implementation", "webflux-reactor")
        .publishPercentileHistogram()
        .register(registry);
  }

  public Mono<CheckoutResult> record(Mono<CheckoutResult> operation) {
    return Mono.defer(() -> {
      Timer.Sample sample = Timer.start(registry);
      return operation
          .doOnNext(ignored -> completed.increment())
          .doOnError(ignored -> failed.increment())
          .doFinally(ignored -> sample.stop(duration));
    });
  }
}
