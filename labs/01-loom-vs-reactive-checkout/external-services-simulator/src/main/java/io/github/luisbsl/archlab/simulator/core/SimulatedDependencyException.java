package io.github.luisbsl.archlab.simulator.core;

public class SimulatedDependencyException extends RuntimeException {

  private final String dependency;

  public SimulatedDependencyException(String dependency) {
    super("Simulated failure from " + dependency);
    this.dependency = dependency;
  }

  public String dependency() {
    return dependency;
  }
}
