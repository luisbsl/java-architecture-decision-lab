package io.github.luisbsl.archlab.checkout.mvc.application.port;

import io.github.luisbsl.archlab.checkout.mvc.domain.Customer;

public interface CustomerGateway {

  Customer findById(String customerId);
}
