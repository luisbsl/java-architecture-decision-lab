# Ubuntu 24.04 Development Environment

This guide establishes the supported local environment for the Java Architecture Decision Lab.

## Required state

```text
Ubuntu 24.04 LTS (Noble), 64-bit
JDK 21 exactly
Repository Maven Wrapper
Docker Engine with daemon access
Docker Compose v2 plugin (`docker compose`)
Git, Bash, curl, and Make
```

The root Maven Enforcer rule accepts Java `[21,22)`. A machine whose default `java -version` is JDK 25 will fail the build even though Java 25 is an LTS release.

## Diagnose first

From the repository root:

```bash
cd labs/01-loom-vs-reactive-checkout
./scripts/check-environment.sh
```

The script is diagnostic only. It does not install or reconfigure host packages.

## Fix JDK 25 default: install and select JDK 21

Ubuntu 24.04 provides OpenJDK 21 packages:

```bash
sudo apt update
sudo apt install openjdk-21-jdk
```

List and select alternatives:

```bash
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

Select paths under `/usr/lib/jvm/java-21-openjdk-*` and verify:

```bash
java -version
javac -version
readlink -f "$(command -v java)"
./mvnw -version
```

For a shell-local override without changing the system default:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

Adjust the architecture suffix when not using amd64.

## Diagnose the current Docker package family

Run:

```bash
docker --version
apt-cache policy docker.io docker.io-app docker-ce docker-ce-cli \
  docker-compose-v2 docker-compose-plugin

dpkg-query -W -f='${binary:Package}\t${Version}\n' 2>/dev/null \
  docker.io docker.io-app docker-ce docker-ce-cli \
  docker-compose-v2 docker-compose-plugin || true
```

A Docker version ending in a suffix such as `0ubuntu...~24.04...` normally indicates Ubuntu-packaged Docker. Docker CE packages from Docker's official repository use a different package family.

Do not mix the Ubuntu `docker.io` family and Docker CE family blindly. Choose one path.

## Path A — minimal repair for Ubuntu-packaged Docker

The observed environment:

```text
Docker version 29.1.3, build 29.1.3-0ubuntu3~24.04.2
docker: unknown command: docker compose
```

is consistent with Ubuntu's Docker package being present while its Compose v2 package is missing. The least disruptive repair is:

```bash
sudo apt update
sudo apt install docker-compose-v2
```

If the package is not found, enable Ubuntu's `universe` component and retry:

```bash
sudo add-apt-repository universe
sudo apt update
sudo apt install docker-compose-v2
```

Validate:

```bash
docker compose version
docker compose -f labs/01-loom-vs-reactive-checkout/docker-compose.yml config --quiet
```

## Path B — normalize onto Docker's official apt repository

Docker's official Ubuntu installation installs this coherent package set:

```text
docker-ce
docker-ce-cli
containerd.io
docker-buildx-plugin
docker-compose-plugin
```

This path is recommended when you intentionally want Docker-maintained packages and update cadence. It requires removing conflicting distro packages first. Before changing package families, inspect and back up anything important under Docker-managed storage and record existing images, containers, volumes, networks, and daemon configuration.

Follow Docker's official Ubuntu apt-repository procedure, then install:

```bash
sudo apt install docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

Do not install only `docker-compose-plugin` from Docker's repository on top of an unexamined distro package mix.

Validate:

```bash
systemctl status docker --no-pager
docker --version
docker compose version
docker run --rm hello-world
```

## Docker daemon access

Check daemon access:

```bash
docker info
```

Repository commands must not use `sudo`.

When `docker info` succeeds as the current user, run every repository Docker and
Compose command directly. Do not retry a failed repository command with
`sudo`, because that changes the execution identity and may create
root-owned files or hide an incorrect local permission configuration.

If direct daemon access is unavailable, Docker documents adding the user to the `docker` group:

```bash
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER"
newgrp docker
```

Then verify:

```bash
docker run --rm hello-world
```

**Security warning:** membership in the `docker` group grants root-level privileges. Use it only when you accept that security model; rootless Docker is the stronger isolation alternative.

On Ubuntu, Docker normally starts at boot. Verify explicitly:

```bash
systemctl is-enabled docker.service
systemctl is-active docker.service
```

## Repository validation after remediation

```bash
cd labs/01-loom-vs-reactive-checkout
./scripts/check-environment.sh
cd ../../..

./mvnw --batch-mode --no-transfer-progress clean verify

docker compose \
  -f labs/01-loom-vs-reactive-checkout/docker-compose.yml \
  config --quiet

make -C labs/01-loom-vs-reactive-checkout up
make -C labs/01-loom-vs-reactive-checkout smoke
make -C labs/01-loom-vs-reactive-checkout down
```

A formal evidence session starts only after all checks succeed with a clean Git worktree.

## Official references

- [Docker Engine installation on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose plugin installation](https://docs.docker.com/compose/install/linux/)
- [Docker Engine Linux post-installation](https://docs.docker.com/engine/install/linux-postinstall/)
- [Ubuntu package: docker-compose-v2](https://packages.ubuntu.com/noble-updates/docker-compose-v2)
- [Ubuntu package: openjdk-21-jdk](https://packages.ubuntu.com/noble/openjdk-21-jdk)
