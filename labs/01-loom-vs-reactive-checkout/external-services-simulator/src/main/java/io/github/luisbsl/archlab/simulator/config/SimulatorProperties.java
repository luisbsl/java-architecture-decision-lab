package io.github.luisbsl.archlab.simulator.config;

import java.time.Duration;
import java.util.Objects;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "simulator")
public record SimulatorProperties(
    boolean deterministic,
    long seed,
    ServiceProfile customer,
    ServiceProfile inventory,
    ServiceProfile payment) {

  public SimulatorProperties {
    Objects.requireNonNull(customer, "customer profile is required");
    Objects.requireNonNull(inventory, "inventory profile is required");
    Objects.requireNonNull(payment, "payment profile is required");
  }

  public ServiceProfile profileFor(SimulatedService service) {
    return switch (service) {
      case CUSTOMER -> customer;
      case INVENTORY -> inventory;
      case PAYMENT -> payment;
    };
  }

  public record ServiceProfile(Duration minDelay, Duration maxDelay, double failureRate) {

    public ServiceProfile {
      Objects.requireNonNull(minDelay, "minDelay is required");
      Objects.requireNonNull(maxDelay, "maxDelay is required");

      if (minDelay.isNegative()) {
        throw new IllegalArgumentException("minDelay cannot be negative");
      }
      if (maxDelay.compareTo(minDelay) < 0) {
        throw new IllegalArgumentException("maxDelay must be greater than or equal to minDelay");
      }
      if (failureRate < 0.0 || failureRate > 1.0) {
        throw new IllegalArgumentException("failureRate must be between 0.0 and 1.0");
      }
    }
  }
}
