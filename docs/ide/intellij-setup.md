# IntelliJ IDEA Setup

## Import

1. Open IntelliJ IDEA.
2. Select **Open** and choose the repository root.
3. Import the root `pom.xml` as a Maven project when prompted.
4. Configure **Project SDK = Java 21**.
5. Enable automatic Maven reload or reload the Maven project manually.

The repository includes shared run configurations under `.run/`:

- `External Services Simulator`
- `Maven Verify`

## Recommended settings

- File encoding: UTF-8
- Line separator: LF
- Maven runner JRE: Project JDK 21
- Build and run using: IntelliJ IDEA or Maven, but verify with `./mvnw clean verify` before a pull request

## Run the simulator

Use the shared Spring Boot configuration, or run:

```bash
./mvnw -pl labs/01-loom-vs-reactive-checkout/external-services-simulator spring-boot:run
```

## Debugging baseline behavior

Place breakpoints in:

```text
SimulationEngine.simulate(...)
CustomerController.findById(...)
InventoryController.check(...)
PaymentController.authorize(...)
```

Use environment variables to change delays and failure rates without editing source files.
