package io.github.luisbsl.archlab.checkout.webflux.domain;

public record Customer(String customerId, String status, String segment) {

  public boolean active() {
    return "ACTIVE".equals(status);
  }
}
