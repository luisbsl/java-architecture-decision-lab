#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LAB="$ROOT/labs/01-loom-vs-reactive-checkout"
COMPOSE_FILE="$LAB/docker-compose.yml"

cleanup() {
  docker compose -f "$COMPOSE_FILE" down --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_for_http() {
  local service="$1"
  local name="$2"
  local url="$3"
  local attempts="${4:-90}"
  local sleep_seconds="${5:-2}"

  for ((i = 1; i <= attempts; i++)); do
    if curl --fail --silent --show-error "$url" >/dev/null 2>&1; then
      echo "[OK] $name is ready: $url"
      return 0
    fi

    local container_id
    container_id="$(docker compose -f "$COMPOSE_FILE" ps -q "$service")"
    if [[ -n "$container_id" ]]; then
      local state
      state="$(docker inspect --format '{{.State.Status}}' "$container_id" 2>/dev/null || true)"
      if [[ "$state" == "exited" || "$state" == "dead" ]]; then
        echo "[ERROR] $name container stopped before becoming ready (state=$state)." >&2
        docker compose -f "$COMPOSE_FILE" logs --no-color "$service" >&2 || true
        return 1
      fi
    fi

    sleep "$sleep_seconds"
  done

  echo "[ERROR] Timed out waiting for $name: $url" >&2
  docker compose -f "$COMPOSE_FILE" ps >&2 || true
  docker compose -f "$COMPOSE_FILE" logs --no-color >&2 || true
  return 1
}

command -v java >/dev/null 2>&1 || { echo '[ERROR] Java 21 is required.' >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo '[ERROR] Docker is required.' >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo '[ERROR] curl is required.' >&2; exit 1; }
docker info >/dev/null
docker compose version >/dev/null

java_spec="$(java -XshowSettings:properties -version 2>&1 | awk -F= '/java.specification.version/ {gsub(/[[:space:]]/, "", $2); print $2; exit}')"
[[ "$java_spec" == "21" ]] || { echo "[ERROR] Java 21 is required; found $java_spec." >&2; exit 1; }

echo '[1/6] Evidence tooling verification'
"$ROOT/scripts/verify-evidence-tooling.sh"

echo '[2/6] Maven verification'
"$ROOT/mvnw" --batch-mode --no-transfer-progress clean verify

echo '[3/6] Docker Compose validation'
docker compose -f "$COMPOSE_FILE" config --quiet

echo '[4/6] Build and start services'
docker compose -f "$COMPOSE_FILE" up --build --force-recreate -d

echo '[5/6] Wait for services'
wait_for_http 'external-services-simulator' 'external services simulator' 'http://localhost:8083/actuator/health/readiness'
wait_for_http 'mvc-virtual-threads' 'MVC + Virtual Threads' 'http://localhost:8081/actuator/health/readiness'
wait_for_http 'webflux-reactor' 'WebFlux + Reactor' 'http://localhost:8082/actuator/health/readiness'

echo '[6/6] Runtime smoke tests'
"$LAB/scripts/smoke-test.sh"
BASE_URL=http://localhost:8081 "$LAB/scripts/checkout-smoke-test.sh"
BASE_URL=http://localhost:8082 "$LAB/scripts/checkout-smoke-test.sh"
BASE_URL=http://localhost:8081 "$LAB/scripts/observability-smoke-test.sh"
BASE_URL=http://localhost:8082 "$LAB/scripts/observability-smoke-test.sh"

echo '[OK] Full project verification passed.'
