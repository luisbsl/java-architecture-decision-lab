package io.github.luisbsl.archlab.checkout.mvc.application.port;

import io.github.luisbsl.archlab.checkout.mvc.domain.PaymentAuthorization;
import java.math.BigDecimal;

public interface PaymentGateway {

  PaymentAuthorization authorize(
      String orderId, String customerId, BigDecimal amount, String currency);
}
