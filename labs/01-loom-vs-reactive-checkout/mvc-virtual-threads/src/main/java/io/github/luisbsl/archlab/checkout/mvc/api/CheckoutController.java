package io.github.luisbsl.archlab.checkout.mvc.api;

import io.github.luisbsl.archlab.checkout.mvc.application.CheckoutCommand;
import io.github.luisbsl.archlab.checkout.mvc.application.CheckoutItem;
import io.github.luisbsl.archlab.checkout.mvc.application.CheckoutUseCase;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/orders")
public class CheckoutController {

  private final CheckoutUseCase checkoutUseCase;

  public CheckoutController(CheckoutUseCase checkoutUseCase) {
    this.checkoutUseCase = checkoutUseCase;
  }

  @PostMapping("/checkout")
  public ResponseEntity<CheckoutResponse> checkout(@Valid @RequestBody CheckoutRequest request) {
    var result = checkoutUseCase.checkout(toCommand(request));
    var response = new CheckoutResponse(
        result.orderId(),
        result.status(),
        result.authorizationId(),
        result.total(),
        result.currency(),
        result.processedAt());
    return ResponseEntity.status(HttpStatus.CREATED).body(response);
  }

  private static CheckoutCommand toCommand(CheckoutRequest request) {
    List<CheckoutItem> items = request.items().stream()
        .map(item -> new CheckoutItem(item.sku(), item.quantity(), item.unitPrice()))
        .toList();
    return new CheckoutCommand(request.orderId(), request.customerId(), items, request.currency());
  }
}
