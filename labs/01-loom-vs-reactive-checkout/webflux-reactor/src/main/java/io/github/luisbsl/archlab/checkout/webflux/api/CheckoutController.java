package io.github.luisbsl.archlab.checkout.webflux.api;

import io.github.luisbsl.archlab.checkout.webflux.application.CheckoutCommand;
import io.github.luisbsl.archlab.checkout.webflux.application.CheckoutItem;
import io.github.luisbsl.archlab.checkout.webflux.application.CheckoutUseCase;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/orders")
public class CheckoutController {

  private final CheckoutUseCase checkoutUseCase;

  public CheckoutController(CheckoutUseCase checkoutUseCase) {
    this.checkoutUseCase = checkoutUseCase;
  }

  @PostMapping("/checkout")
  public Mono<ResponseEntity<CheckoutResponse>> checkout(
      @Valid @RequestBody CheckoutRequest request) {
    return checkoutUseCase.checkout(toCommand(request))
        .map(result -> ResponseEntity.status(HttpStatus.CREATED).body(new CheckoutResponse(
            result.orderId(),
            result.status(),
            result.authorizationId(),
            result.total(),
            result.currency(),
            result.processedAt())));
  }

  private static CheckoutCommand toCommand(CheckoutRequest request) {
    List<CheckoutItem> items = request.items().stream()
        .map(item -> new CheckoutItem(item.sku(), item.quantity(), item.unitPrice()))
        .toList();
    return new CheckoutCommand(request.orderId(), request.customerId(), items, request.currency());
  }
}
