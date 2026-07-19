package io.github.luisbsl.archlab.checkout.webflux.domain;

public class InactiveCustomerException extends RuntimeException {

  private final String customerId;

  public InactiveCustomerException(String customerId) {
    super("Customer %s is not active".formatted(customerId));
    this.customerId = customerId;
  }

  public String customerId() {
    return customerId;
  }
}
