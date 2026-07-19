package io.github.luisbsl.archlab.checkout.mvc.application.port;

import io.github.luisbsl.archlab.checkout.mvc.domain.ConfirmedOrder;

public interface OrderRepository {

  void save(ConfirmedOrder order);
}
