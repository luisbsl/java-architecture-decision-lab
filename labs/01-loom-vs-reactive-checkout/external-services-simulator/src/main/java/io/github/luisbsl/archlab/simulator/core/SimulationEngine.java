package io.github.luisbsl.archlab.simulator.core;

import io.github.luisbsl.archlab.simulator.config.SimulatedService;
import io.github.luisbsl.archlab.simulator.config.SimulatorProperties;
import java.time.Duration;
import java.util.SplittableRandom;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class SimulationEngine {

  private static final long FNV_OFFSET_BASIS = 0xcbf29ce484222325L;
  private static final long FNV_PRIME = 0x100000001b3L;

  private final SimulatorProperties properties;

  public SimulationEngine(SimulatorProperties properties) {
    this.properties = properties;
  }

  public SimulationResult simulate(SimulatedService service, String workloadKey) {
    var profile = properties.profileFor(service);
    RandomValues values = properties.deterministic() && StringUtils.hasText(workloadKey)
        ? deterministicValues(service, workloadKey)
        : randomValues();
    long delayMillis = delay(profile.minDelay(), profile.maxDelay(), values.delayUnit());

    sleep(delayMillis);

    if (values.failureUnit() < profile.failureRate()) {
      throw new SimulatedDependencyException(service.externalName());
    }

    return new SimulationResult(service.externalName(), delayMillis);
  }

  private RandomValues deterministicValues(SimulatedService service, String workloadKey) {
    long state = FNV_OFFSET_BASIS ^ properties.seed();
    state = hash(state, service.name());
    state = hash(state, workloadKey);
    var random = new SplittableRandom(state);
    return new RandomValues(random.nextDouble(), random.nextDouble());
  }

  private static RandomValues randomValues() {
    var random = ThreadLocalRandom.current();
    return new RandomValues(random.nextDouble(), random.nextDouble());
  }

  private static long hash(long state, String value) {
    long result = state;
    for (int index = 0; index < value.length(); index++) {
      result ^= value.charAt(index);
      result *= FNV_PRIME;
    }
    return result;
  }

  private static long delay(Duration minDelay, Duration maxDelay, double unit) {
    long min = minDelay.toMillis();
    long max = maxDelay.toMillis();
    if (min == max) {
      return min;
    }
    long range = max - min + 1;
    return min + Math.min(range - 1, (long) Math.floor(unit * range));
  }

  private static void sleep(long delayMillis) {
    try {
      Thread.sleep(delayMillis);
    } catch (InterruptedException exception) {
      Thread.currentThread().interrupt();
      throw new SimulationInterruptedException(exception);
    }
  }

  private record RandomValues(double delayUnit, double failureUnit) {}

  public record SimulationResult(String service, long delayMillis) {}
}
