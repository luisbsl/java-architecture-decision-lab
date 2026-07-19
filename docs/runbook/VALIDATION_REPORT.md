# Final Consolidation and Validation Report

**Date:** 2026-07-18  
**Target release:** `v1.0.0`  
**Canonical runbook:** [`MASTER_RUNBOOK.md`](MASTER_RUNBOOK.md)

## Scope

The supplied archive was consolidated into one release-oriented codebase. Delivery-only release-candidate reports, patch notes, and competing operational instructions were removed or replaced by stable documentation.

The final repository contains:

- one Java 21 / Spring Boot multi-module project;
- one external dependency simulator;
- one MVC + Virtual Threads implementation;
- one WebFlux/Reactor implementation;
- one shared Docker Compose runtime;
- one deterministic k6 workload model;
- one evidence pipeline for Docker statistics, Actuator, JVM diagnostics, and JFR;
- one fail-closed suite auditor;
- one canonical end-to-end runbook;
- one clean GitHub publication and `v1.0.0` release workflow.

## Consolidation corrections

The following release-critical inconsistencies were corrected:

1. Every official benchmark instruction now uses **four balanced pairs**. The suite rejects odd pair counts.
2. The formal protocol is consistently represented as **16 isolated runs** for `moderate,high` with four pairs.
3. Formal evidence now requires an initialized repository, committed `HEAD`, exact Git SHA, and clean worktree.
4. Resume now rejects any change in source fingerprint or runtime/resource configuration fingerprint, including CPU, memory, logging, warm-up, thresholds, duration, rates, VUs, and failure/delay overrides.
5. Delivery-only candidate/patch documentation was removed from the product surface.
6. Project and module versions were normalized to `1.0.0`.
7. Maven Wrapper distribution was normalized to the Maven Central `3.9.16` archive with SHA-512 verification.
8. A repository consistency verifier was added and integrated into the evidence-tooling gate. It evaluates Git source files rather than ignored local runtime artifacts.
9. Missing generated-evidence navigation was replaced with a valid `LATEST.md` entry point.
10. Maven and GitHub Actions dependency update automation was enabled through Dependabot.
11. The evidence verifier no longer uses `compileall` inside the repository. Python sources are parsed without bytecode writes, unit tests run with bytecode disabled, and the gate is verified again at the end.
12. Repository consistency now evaluates tracked and non-ignored source files when Git is initialized, so ignored local outputs cannot poison a valid working tree.

## Validation completed in this environment

The following checks passed:

- repository structure, versions, wrapper metadata, protocol defaults, generated-artifact hygiene, executable scripts, and relative Markdown links;
- Bash syntax validation for all repository shell scripts;
- six automated Python tests covering evidence aggregation, exact measurement-window bounding, memory-unit normalization, run-summary generation, and controlled-arrival boundary handling;
- non-mutating Python AST syntax validation;
- standalone Java compilation and execution of the JFR metrics extractor performed by `verify-evidence-tooling.sh`;
- JFR profile validation performed by `verify-evidence-tooling.sh`;
- XML parsing for the root POM and all three module POMs;
- help/argument smoke checks for the single-run and paired-suite runners;
- absence of build outputs, Python caches, local evidence directories, and delivery-only artifacts in the final package.

Primary offline gate:

```bash
./scripts/verify-evidence-tooling.sh
```

Observed final status:

```text
[OK] Evidence tooling verification passed.
```

### Verification-contract regression

The exact failure sequence from the first delivery was reproduced and corrected:

```bash
./scripts/verify-evidence-tooling.sh
./scripts/verify-evidence-tooling.sh
./scripts/verify-repository-consistency.py
```

The sequence passed twice consecutively with `fresh_cache_count=0`. A second regression fixture initialized Git, deliberately generated the eight ignored `__pycache__`/`.pyc` entries produced by the previous implementation, and confirmed that source consistency and evidence verification still pass while `git status --short` remains empty.


## Published evidence provenance

The curated suite was measured with protocol version `4`, Git SHA `14d95f82c6557a7cf5005d80dc2536923aa91ecf`, and the immutable runtime/workload configuration recorded in `suite.env`. The public source delivery contains later post-processing and verification hardening only; the Java applications, Dockerfiles, workload JavaScript, and runtime YAML measured by the suite were not changed.

The current runner uses protocol version `5` for future suites because protocol fingerprint ordering is now forced to `LC_ALL=C`, making source identity independent of host locale. Protocol v4 evidence remains historical and must not be relabeled as v5.

## Runtime validation not executable in this sandbox

This execution environment did not provide:

- Docker CLI/daemon;
- a preinstalled Maven binary or dependency cache;
- outbound DNS access from the container for Maven dependency resolution.

Therefore, the following were **not falsely reported as executed** here:

- `./mvnw clean verify` for the complete Spring reactor;
- Docker image builds;
- Compose startup and readiness;
- runtime smoke tests;
- k6/JFR formal benchmark runs.

The definitive runtime/release gate is already automated:

```bash
./scripts/verify-all.sh
```

It must pass on the target workstation and on GitHub Actions before the `v1.0.0` tag is created. A release must not be described as runtime-validated until this command and CI pass on the exact release commit.

## Required final execution order

```bash
# 1. Validate environment
labs/01-loom-vs-reactive-checkout/scripts/check-environment.sh

# 2. Initialize one clean history
git init -b main
git add .
git commit -m "feat: publish complete Java architecture decision lab"

# 3. Offline/tooling gate
./scripts/verify-evidence-tooling.sh

# 4. Complete build + Docker runtime gate
./scripts/verify-all.sh

# 5. Validate the already-curated publication evidence
make -C labs/01-loom-vs-reactive-checkout evidence-validate \
  CURATED_DIR=docs/results/evidence/20260718T215210Z-paired-evidence

# 6. Future measurements only
# Follow MASTER_RUNBOOK.md sections 7–13 using the current protocol version.
```

## Release decision

The codebase is **consolidated and statically/tooling validated**. Final runtime acceptance remains intentionally fail-closed and depends on successful execution of `./scripts/verify-all.sh` on the exact release commit and `SUITE_AUDIT.md = PASS` for the already-curated publication evidence. A new formal suite is required only for future measurements or changes to the measured runtime/workload, not to republish immutable historical evidence.

## Post-processing regression: controlled-arrival boundary and finalization

The suite auditor now distinguishes a true workload mismatch from the normal one-iteration scheduling boundary of k6 `constant-arrival-rate`. A pair passes only when both executions remain within `±1` iteration of `configured rate × measured duration`, the pair delta is at most one, dropped iterations remain zero, and all other per-run integrity gates pass. The accepted boundary delta is recorded as a warning rather than hidden.

A complete `16/16` suite that fails only during aggregation or audit must be finalized with `evidence-finalize`; it must not be resumed or re-executed. The final audit records its policy version and the SHA-256 of the auditor implementation.
