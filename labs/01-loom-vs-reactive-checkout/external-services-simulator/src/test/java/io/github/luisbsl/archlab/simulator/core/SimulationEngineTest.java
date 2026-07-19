package io.github.luisbsl.archlab.simulator.core;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.luisbsl.archlab.simulator.config.SimulatedService;
import io.github.luisbsl.archlab.simulator.config.SimulatorProperties;
import java.time.Duration;
import org.junit.jupiter.api.Test;

class SimulationEngineTest {

  @Test
  void producesTheSameDelayForTheSameWorkloadIdentity() {
    var profile = new SimulatorProperties.ServiceProfile(
        Duration.ZERO, Duration.ofMillis(10), 0.0);
    var properties = new SimulatorProperties(true, 42L, profile, profile, profile);
    var engine = new SimulationEngine(properties);

    var first = engine.simulate(SimulatedService.PAYMENT, "pair-01-iteration-99");
    var second = engine.simulate(SimulatedService.PAYMENT, "pair-01-iteration-99");

    assertThat(second.delayMillis()).isEqualTo(first.delayMillis());
  }
}
