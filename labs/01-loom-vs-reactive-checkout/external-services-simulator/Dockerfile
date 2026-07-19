FROM maven:3.9.16-eclipse-temurin-21 AS build
WORKDIR /workspace

COPY pom.xml ./pom.xml
COPY labs/01-loom-vs-reactive-checkout/external-services-simulator/pom.xml \
  labs/01-loom-vs-reactive-checkout/external-services-simulator/pom.xml
COPY labs/01-loom-vs-reactive-checkout/mvc-virtual-threads/pom.xml \
  labs/01-loom-vs-reactive-checkout/mvc-virtual-threads/pom.xml
COPY labs/01-loom-vs-reactive-checkout/webflux-reactor/pom.xml \
  labs/01-loom-vs-reactive-checkout/webflux-reactor/pom.xml


RUN mvn --batch-mode --no-transfer-progress \
  -pl labs/01-loom-vs-reactive-checkout/external-services-simulator \
  -am dependency:go-offline

COPY labs/01-loom-vs-reactive-checkout/external-services-simulator/src \
  labs/01-loom-vs-reactive-checkout/external-services-simulator/src

RUN mvn --batch-mode --no-transfer-progress \
  -pl labs/01-loom-vs-reactive-checkout/external-services-simulator \
  -am package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app

RUN useradd --system --uid 10001 spring

COPY --from=build \
  /workspace/labs/01-loom-vs-reactive-checkout/external-services-simulator/target/external-services-simulator-*.jar \
  /app/application.jar

EXPOSE 8083
USER 10001

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-jar", "/app/application.jar"]
