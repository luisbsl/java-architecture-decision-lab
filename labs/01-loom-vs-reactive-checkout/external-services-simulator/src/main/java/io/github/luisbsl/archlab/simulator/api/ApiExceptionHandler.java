package io.github.luisbsl.archlab.simulator.api;

import io.github.luisbsl.archlab.simulator.core.SimulatedDependencyException;
import io.github.luisbsl.archlab.simulator.core.SimulationInterruptedException;
import jakarta.validation.ConstraintViolationException;
import java.net.URI;
import java.time.Instant;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {

  @ExceptionHandler(SimulatedDependencyException.class)
  ProblemDetail handleSimulatedFailure(SimulatedDependencyException exception) {
    var problem = ProblemDetail.forStatusAndDetail(
        HttpStatus.SERVICE_UNAVAILABLE,
        exception.getMessage());
    problem.setTitle("Simulated downstream failure");
    problem.setType(URI.create("urn:problem:simulated-downstream-failure"));
    problem.setProperty("dependency", exception.dependency());
    problem.setProperty("timestamp", Instant.now());
    return problem;
  }

  @ExceptionHandler(SimulationInterruptedException.class)
  ProblemDetail handleInterruptedSimulation(SimulationInterruptedException exception) {
    var problem = ProblemDetail.forStatusAndDetail(
        HttpStatus.SERVICE_UNAVAILABLE,
        exception.getMessage());
    problem.setTitle("Simulation interrupted");
    problem.setType(URI.create("urn:problem:simulation-interrupted"));
    problem.setProperty("timestamp", Instant.now());
    return problem;
  }

  @ExceptionHandler({MethodArgumentNotValidException.class, ConstraintViolationException.class})
  ProblemDetail handleValidation(Exception exception) {
    var problem = ProblemDetail.forStatusAndDetail(
        HttpStatus.BAD_REQUEST,
        "The request contains invalid data.");
    problem.setTitle("Validation failed");
    problem.setType(URI.create("urn:problem:validation"));
    problem.setProperty("timestamp", Instant.now());
    problem.setProperty("cause", exception.getClass().getSimpleName());
    return problem;
  }
}
