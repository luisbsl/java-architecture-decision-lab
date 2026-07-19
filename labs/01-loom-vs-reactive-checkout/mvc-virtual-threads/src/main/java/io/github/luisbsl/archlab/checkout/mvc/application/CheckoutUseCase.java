package io.github.luisbsl.archlab.checkout.mvc.application;

public interface CheckoutUseCase {

  CheckoutResult checkout(CheckoutCommand command);
}
