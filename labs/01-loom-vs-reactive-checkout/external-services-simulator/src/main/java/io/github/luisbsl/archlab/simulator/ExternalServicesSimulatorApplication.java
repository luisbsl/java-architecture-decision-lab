package io.github.luisbsl.archlab.simulator;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class ExternalServicesSimulatorApplication {

  public static void main(String[] args) {
    SpringApplication.run(ExternalServicesSimulatorApplication.class, args);
  }
}
