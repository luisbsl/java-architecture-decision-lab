SHELL := /usr/bin/env bash
ROOT := $(abspath ../..)

# Paths passed to `make -C` are interpreted as repository-root-relative unless absolute.
repo_path = $(if $(filter /%,$(strip $(1))),$(strip $(1)),$(abspath $(ROOT)/$(strip $(1))))
COMPOSE := docker compose -f docker-compose.yml

.PHONY: help build test verify up up-simulator up-mvc up-webflux down logs smoke smoke-simulator smoke-mvc smoke-webflux smoke-observability load-functional load-moderate evidence-environment evidence-mvc evidence-webflux evidence-suite evidence-tooling evidence-docs evidence-charts evidence-validate evidence-audit evidence-finalize evidence-package evidence-curate evidence-release visualvm-mvc visualvm-webflux visualvm-stop clean

help:
	@echo "Available targets:"
	@echo "  build            Package the Maven reactor"
	@echo "  test             Run tests"
	@echo "  verify           Run the full Maven verification lifecycle"
	@echo "  up               Build and start every currently implemented service"
	@echo "  up-simulator     Start only the simulator"
	@echo "  up-mvc           Start simulator and MVC + Virtual Threads"
	@echo "  up-webflux       Start simulator and WebFlux/Reactor"
	@echo "  down             Stop and remove lab containers"
	@echo "  logs             Follow all service logs"
	@echo "  smoke            Exercise every currently implemented service"
	@echo "  smoke-simulator  Exercise simulator endpoints"
	@echo "  smoke-mvc        Exercise MVC checkout"
	@echo "  smoke-webflux    Exercise WebFlux checkout"
	@echo "  smoke-observability Validate Actuator and correlation parity"
	@echo "  load-functional   Run functional k6 against both implementations"
	@echo "  load-moderate     Run moderate k6 against both implementations"
	@echo "  evidence-environment Capture formal environment metadata"
	@echo "  evidence-mvc       Run one automated MVC moderate evidence session"
	@echo "  evidence-webflux   Run one automated WebFlux moderate evidence session"
	@echo "  evidence-suite     Run paired evidence; supports SCENARIOS, PAIRS, RESUME, RUN_TIMEOUT_SECONDS"
	@echo "  evidence-tooling   Validate evidence scripts, parsers, JFR profile and Compose"
	@echo "  evidence-audit     Fail closed on SUITE_DIR integrity/protocol violations"
	@echo "  evidence-docs      Extract JFR metrics, generate Mermaid charts, update docs, and validate checksums"
	@echo "  evidence-charts    Generate Mermaid charts from CURATED_DIR aggregates"
	@echo "  evidence-validate  Validate latest curated evidence manifest (or CURATED_DIR)"
	@echo "  evidence-package   Package SUITE_DIR as a release artifact"
	@echo "  evidence-curate    Export small sanitized artifacts from SUITE_DIR into docs"
	@echo "  evidence-release   Upload SUITE_DIR to GitHub RELEASE_TAG"
	@echo "  visualvm-mvc       Start a native MVC VisualVM session"
	@echo "  visualvm-webflux   Start a native WebFlux VisualVM session"
	@echo "  visualvm-stop      Stop the active VisualVM session"
	@echo "  clean            Remove Maven build outputs"

build:
	cd $(ROOT) && ./mvnw --no-transfer-progress -DskipTests package

test:
	cd $(ROOT) && ./mvnw --no-transfer-progress test

verify:
	cd $(ROOT) && ./mvnw --no-transfer-progress clean verify

up:
	$(COMPOSE) up --build -d

up-simulator:
	$(COMPOSE) up --build -d external-services-simulator

up-mvc:
	$(COMPOSE) up --build -d external-services-simulator mvc-virtual-threads

up-webflux:
	$(COMPOSE) up --build -d external-services-simulator webflux-reactor

down:
	$(COMPOSE) down --remove-orphans

logs:
	$(COMPOSE) logs -f

smoke: smoke-simulator smoke-mvc smoke-webflux smoke-observability

smoke-simulator:
	./scripts/smoke-test.sh

smoke-mvc:
	BASE_URL=http://localhost:8081 ./scripts/checkout-smoke-test.sh

smoke-webflux:
	BASE_URL=http://localhost:8082 ./scripts/checkout-smoke-test.sh

smoke-observability:
	BASE_URL=http://localhost:8081 ./scripts/observability-smoke-test.sh
	BASE_URL=http://localhost:8082 ./scripts/observability-smoke-test.sh

load-functional:
	IMPLEMENTATION=mvc-vthreads SCENARIO=functional ./scripts/run-load-test.sh
	IMPLEMENTATION=webflux-reactor SCENARIO=functional ./scripts/run-load-test.sh

load-moderate:
	IMPLEMENTATION=mvc-vthreads SCENARIO=moderate ./scripts/run-load-test.sh
	IMPLEMENTATION=webflux-reactor SCENARIO=moderate ./scripts/run-load-test.sh

evidence-environment:
	IMPLEMENTATION=$${IMPLEMENTATION:-mvc-vthreads} SCENARIO=$${SCENARIO:-functional} ./scripts/capture-environment.sh

evidence-mvc:
	./scripts/run-evidence.sh --implementation mvc-vthreads --scenario $${SCENARIO:-moderate}

evidence-webflux:
	./scripts/run-evidence.sh --implementation webflux-reactor --scenario $${SCENARIO:-moderate}

evidence-suite:
	./scripts/run-evidence-suite.sh --scenarios $${SCENARIOS:-moderate} --pairs $${PAIRS:-4} --cooldown-seconds $${COOLDOWN_SECONDS:-10} --workload-seed $${WORKLOAD_SEED:-20260718} $${RESUME:+--resume "$${RESUME}"} $${RUN_TIMEOUT_SECONDS:+--run-timeout-seconds "$${RUN_TIMEOUT_SECONDS}"}

evidence-tooling:
	$(ROOT)/scripts/verify-evidence-tooling.sh

evidence-docs:
	./scripts/materialize-evidence-docs.sh $(if $(SUITE_DIR),"$(call repo_path,$(SUITE_DIR))",) $(if $(UPDATE_ANALYSIS),--update-analysis,) $(if $(REFRESH_JFR),--refresh-jfr,) $(if $(ALLOW_PARTIAL),--allow-partial,) $(if $(ALLOW_UNKNOWN_GIT),--allow-unknown-git,)

evidence-charts:
	@test -n "$${CURATED_DIR}" || (echo "Set CURATED_DIR" >&2; exit 2)
	./scripts/generate-mermaid-charts.py "$(call repo_path,$(CURATED_DIR))"

evidence-validate:
	./scripts/validate-curated-evidence.sh $(if $(CURATED_DIR),"$(call repo_path,$(CURATED_DIR))",)

evidence-audit:
	@test -n "$${SUITE_DIR}" || (echo "Set SUITE_DIR" >&2; exit 2)
	./scripts/audit-evidence-suite.py "$(call repo_path,$(SUITE_DIR))"

evidence-finalize:
	@test -n "$${SUITE_DIR}" || (echo "Set SUITE_DIR" >&2; exit 2)
	./scripts/finalize-evidence-suite.sh "$(call repo_path,$(SUITE_DIR))"

evidence-package:
	@test -n "$${SUITE_DIR}" || (echo "Set SUITE_DIR" >&2; exit 2)
	./scripts/package-evidence.sh "$(call repo_path,$(SUITE_DIR))"

evidence-curate:
	@test -n "$${SUITE_DIR}" || (echo "Set SUITE_DIR" >&2; exit 2)
	./scripts/export-curated-evidence.sh "$(call repo_path,$(SUITE_DIR))"

evidence-release:
	@test -n "$${SUITE_DIR}" || (echo "Set SUITE_DIR" >&2; exit 2)
	@test -n "$${RELEASE_TAG}" || (echo "Set RELEASE_TAG" >&2; exit 2)
	./scripts/publish-evidence-release.sh "$(call repo_path,$(SUITE_DIR))" "$${RELEASE_TAG}"

visualvm-mvc:
	./scripts/visualvm-session.sh start mvc-vthreads

visualvm-webflux:
	./scripts/visualvm-session.sh start webflux-reactor

visualvm-stop:
	./scripts/visualvm-session.sh stop

clean:
	cd $(ROOT) && ./mvnw clean
