#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd -- "$LAB_DIR/../.." && pwd)"
ERRORS=0
WARNINGS=0

info() { printf '[INFO] %s\n' "$*"; }
ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; WARNINGS=$((WARNINGS + 1)); }
error() { printf '[ERROR] %s\n' "$*" >&2; ERRORS=$((ERRORS + 1)); }

has_command() {
  command -v "$1" >/dev/null 2>&1
}

check_command() {
  local command_name="$1"
  local purpose="$2"
  if has_command "$command_name"; then
    ok "$command_name is available for $purpose: $(command -v "$command_name")"
  else
    error "$command_name is required for $purpose but was not found."
  fi
}

java_major() {
  java -XshowSettings:properties -version 2>&1 \
    | awk -F= '/^[[:space:]]*java\.specification\.version[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2; exit}'
}

print_java_remediation() {
  cat >&2 <<'MSG'
[REMEDIATION] Ubuntu 24.04:
  sudo apt update
  sudo apt install openjdk-21-jdk
  sudo update-alternatives --config java
  sudo update-alternatives --config javac
See docs/environment/ubuntu-24.04-development-environment.md.
MSG
}

print_compose_remediation() {
  local ubuntu_docker="false"
  if dpkg-query -W -f='${Status}' docker.io-app 2>/dev/null | grep -q 'install ok installed' \
     || dpkg-query -W -f='${Status}' docker.io 2>/dev/null | grep -q 'install ok installed'; then
    ubuntu_docker="true"
  fi

  if [[ "$ubuntu_docker" == "true" ]]; then
    cat >&2 <<'MSG'
[REMEDIATION] Ubuntu-packaged Docker detected. Install Compose v2 with:
  sudo apt update
  sudo apt install docker-compose-v2
MSG
  else
    cat >&2 <<'MSG'
[REMEDIATION] If Docker Engine was installed from Docker's official apt repository:
  sudo apt update
  sudo apt install docker-compose-plugin
MSG
  fi
  cat >&2 <<'MSG'
Do not mix Docker package families without reviewing the environment guide:
  docs/environment/ubuntu-24.04-development-environment.md
MSG
}

info "Repository root: $REPO_ROOT"
info "Operating system"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf '%s\n' "${PRETTY_NAME:-unknown}"
else
  warn "/etc/os-release is unavailable."
fi

info "Baseline commands"
check_command git "version control"
check_command bash "repository scripts"
check_command curl "HTTP smoke tests"
check_command make "Makefile workflows"

info "Java runtime"
if has_command java; then
  java -version
  JAVA_MAJOR="$(java_major || true)"
  if [[ "$JAVA_MAJOR" == "21" ]]; then
    ok "Java specification version is exactly 21."
  else
    error "Java 21 is required; detected specification version '${JAVA_MAJOR:-unknown}'."
    print_java_remediation
  fi
else
  error "Java is not installed."
  print_java_remediation
fi

info "Java compiler"
if has_command javac; then
  javac -version
  JAVAC_VERSION="$(javac -version 2>&1 | awk '{print $2}')"
  if [[ "$JAVAC_VERSION" == 21* ]]; then
    ok "javac is Java 21."
  else
    error "javac 21 is required; detected '${JAVAC_VERSION:-unknown}'."
  fi
else
  error "javac is not installed; a full JDK 21 is required."
fi

info "Maven Wrapper"
if [[ -x "$REPO_ROOT/mvnw" ]]; then
  ok "Maven Wrapper is executable."
  if "$REPO_ROOT/mvnw" --version; then
    ok "Maven Wrapper executed successfully."
  else
    error "Maven Wrapper could not execute. Check network/proxy/cache and JDK 21 selection."
  fi
else
  error "Expected executable Maven Wrapper at $REPO_ROOT/mvnw."
fi

info "Docker CLI"
if has_command docker; then
  docker --version
  ok "Docker CLI is available."

  info "Docker daemon"
  if docker info >/dev/null 2>&1; then
    ok "Docker daemon is reachable by the current user."
  else
    error "Docker CLI is installed, but the daemon is not reachable by the current user. Repository commands must not retry with sudo; inspect the Docker service and socket permissions separately."
  fi

  info "Docker Compose v2 plugin"
  if docker compose version; then
    ok "Docker Compose v2 plugin is available."
  else
    error "Docker Compose v2 is required, but 'docker compose' is unavailable."
    if has_command docker-compose; then
      warn "Legacy 'docker-compose' exists, but this repository requires the Compose v2 subcommand."
    fi
    print_compose_remediation
  fi
else
  error "Docker CLI is not installed."
  cat >&2 <<'MSG'
[REMEDIATION] Follow docs/environment/ubuntu-24.04-development-environment.md and the official Docker Ubuntu installation guide.
MSG
fi


info "Evidence and profiling commands"
for tool in python3 jcmd jfr k6; do
  if has_command "$tool"; then
    ok "$tool is available: $(command -v "$tool")"
  else
    warn "$tool is not required for baseline verification, but is required for automated performance evidence."
  fi
done
if has_command visualvm; then
  ok "VisualVM is available: $(command -v visualvm)"
else
  warn "VisualVM is optional and required only for curated interactive captures."
fi

printf '\n[SUMMARY] errors=%d warnings=%d\n' "$ERRORS" "$WARNINGS"
if (( ERRORS > 0 )); then
  printf '[FAILED] Baseline environment is not ready.\n' >&2
  exit 1
fi

printf '[OK] Baseline environment is ready.\n'
