package io.github.luisbsl.archlab.checkout.webflux;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class WebFluxReactorApplication {

  public static void main(String[] args) {
    SpringApplication.run(WebFluxReactorApplication.class, args);
  }
}
