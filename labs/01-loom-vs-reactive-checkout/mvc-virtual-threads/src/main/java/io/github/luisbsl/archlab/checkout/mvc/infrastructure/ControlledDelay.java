package io.github.luisbsl.archlab.checkout.mvc.infrastructure;

import java.time.Duration;

final class ControlledDelay {

  private ControlledDelay() {}

  static void sleep(Duration duration) {
    try {
      Thread.sleep(duration);
    } catch (InterruptedException exception) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException("Controlled checkout delay was interrupted", exception);
    }
  }
}
