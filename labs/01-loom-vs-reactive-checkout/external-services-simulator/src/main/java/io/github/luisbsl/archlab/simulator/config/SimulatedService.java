package io.github.luisbsl.archlab.simulator.config;

public enum SimulatedService {
  CUSTOMER("customer-service"),
  INVENTORY("inventory-service"),
  PAYMENT("payment-service");

  private final String externalName;

  SimulatedService(String externalName) {
    this.externalName = externalName;
  }

  public String externalName() {
    return externalName;
  }
}
