package io.github.luisbsl.archlab.simulator.core;

public class SimulationInterruptedException extends RuntimeException {

  public SimulationInterruptedException(InterruptedException cause) {
    super("The simulated dependency call was interrupted", cause);
  }
}
