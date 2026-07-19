package io.github.luisbsl.archlab.checkout.mvc.api;

import io.github.luisbsl.archlab.checkout.mvc.domain.InactiveCustomerException;
import io.github.luisbsl.archlab.checkout.mvc.domain.InventoryUnavailableException;
import jakarta.validation.ConstraintViolationException;
import java.net.URI;
import java.time.Instant;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.client.RestClientException;

@RestControllerAdvice
public class ApiExceptionHandler {

  @ExceptionHandler({MethodArgumentNotValidException.class, ConstraintViolationException.class})
  ProblemDetail handleValidation(Exception exception) {
    return problem(HttpStatus.BAD_REQUEST, "Validation failed",
        "The checkout request contains invalid data.", "urn:problem:validation");
  }

  @ExceptionHandler(InventoryUnavailableException.class)
  ProblemDetail handleInventory(InventoryUnavailableException exception) {
    var problem = problem(HttpStatus.CONFLICT, "Inventory unavailable",
        exception.getMessage(), "urn:problem:inventory-unavailable");
    problem.setProperty("sku", exception.sku());
    return problem;
  }

  @ExceptionHandler(InactiveCustomerException.class)
  ProblemDetail handleInactiveCustomer(InactiveCustomerException exception) {
    var problem = problem(HttpStatus.UNPROCESSABLE_ENTITY, "Customer cannot checkout",
        exception.getMessage(), "urn:problem:inactive-customer");
    problem.setProperty("customerId", exception.customerId());
    return problem;
  }

  @ExceptionHandler(RestClientException.class)
  ProblemDetail handleDownstream(RestClientException exception) {
    return problem(HttpStatus.SERVICE_UNAVAILABLE, "Downstream dependency failure",
        "A required simulated dependency did not complete successfully.",
        "urn:problem:downstream-dependency");
  }

  private static ProblemDetail problem(
      HttpStatus status, String title, String detail, String type) {
    var problem = ProblemDetail.forStatusAndDetail(status, detail);
    problem.setTitle(title);
    problem.setType(URI.create(type));
    problem.setProperty("timestamp", Instant.now());
    return problem;
  }
}
