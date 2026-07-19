# Contributing

Thank you for helping improve the Java Architecture Decision Lab.

This project values **reproducibility, explicit trade-offs, small pull requests, and honest limitations** more than impressive-looking benchmark numbers.

## Development setup

```bash
git clone <repository-url>
cd java-architecture-decision-lab
./mvnw clean verify
```

Use JDK 21. IntelliJ users should import the root `pom.xml` as a Maven project and enable the shared configurations under `.run/`.

## Branching

Create work from `main`:

```bash
git switch main
git pull --ff-only
git switch -c feature/<descriptive-name>
```

Do not commit directly to `main`; use a focused feature branch and a pull request.

## Commit convention

Use Conventional Commits:

```text
feat: add baseline customer simulator
fix: validate payment amount
 docs: clarify profiling limitations
 test: cover configured simulator failures
 chore: update Maven wrapper
```

Recommended scopes:

```text
repo
simulator
mvc-vthreads
webflux
observability
load-tests
profiling
results
```

Example:

```text
feat(simulator): add configurable downstream latency
```

## Pull requests

Every pull request must answer:

- What architectural question does this change help answer?
- How can another engineer reproduce it?
- What evidence is included?
- What becomes simpler and what becomes harder?
- What does the pull request **not** prove?

Use the repository pull request template.

## Quality bar

Before opening a pull request:

```bash
./mvnw clean verify
```

Confirm that:

- code compiles on Java 21;
- tests pass;
- commands and configuration are documented;
- no credentials or sensitive data are committed;
- results describe the machine and test conditions;
- large JFR, heap dump, or profiler files are not committed.

## Results and evidence

Prefer versioning:

- Markdown analysis;
- small CSV files;
- sanitized screenshots;
- commands and configuration required to reproduce results.

Avoid versioning:

- raw heap dumps;
- large JFR recordings;
- environment-specific secrets;
- conclusions without test conditions.

## Code of conduct

Be rigorous about ideas and respectful toward people. Framework preference is not a substitute for evidence.
