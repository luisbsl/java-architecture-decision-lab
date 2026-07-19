package io.github.luisbsl.archlab.checkout.mvc;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class MvcVirtualThreadsApplication {

  public static void main(String[] args) {
    SpringApplication.run(MvcVirtualThreadsApplication.class, args);
  }
}
