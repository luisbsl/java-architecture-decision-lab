package io.github.luisbsl.archlab.checkout.mvc.observability;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import java.util.function.Supplier;
import org.springframework.stereotype.Component;

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
        .tag("implementation", "mvc-vthreads")
        .register(registry);
    this.failed = Counter.builder("checkout.failed")
        .description("Checkout failures")
        .tag("implementation", "mvc-vthreads")
        .register(registry);
    this.duration = Timer.builder("checkout.duration")
        .description("End-to-end checkout duration")
        .tag("implementation", "mvc-vthreads")
        .publishPercentileHistogram()
        .register(registry);
  }

  public <T> T record(Supplier<T> operation) {
    Timer.Sample sample = Timer.start(registry);
    try {
      T result = operation.get();
      completed.increment();
      return result;
    } catch (RuntimeException exception) {
      failed.increment();
      throw exception;
    } finally {
      sample.stop(duration);
    }
  }
}
