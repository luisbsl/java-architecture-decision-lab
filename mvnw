#!/usr/bin/env sh
# Lightweight Maven wrapper for this repository.
# Downloads and verifies the Maven distribution declared in
# .mvn/wrapper/maven-wrapper.properties.

set -eu

BASE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROPS="$BASE_DIR/.mvn/wrapper/maven-wrapper.properties"

if [ ! -f "$PROPS" ]; then
  echo "[ERROR] Missing $PROPS" >&2
  exit 1
fi

property() {
  sed -n "s/^$1=//p" "$PROPS" | tail -n 1
}

DIST_URL=$(property distributionUrl)
DIST_SHA512=$(property distributionSha512Sum)

if [ -z "$DIST_URL" ]; then
  echo "[ERROR] distributionUrl is not configured." >&2
  exit 1
fi

MAVEN_USER_HOME=${MAVEN_USER_HOME:-"$HOME/.m2"}
ARCHIVE_NAME=${DIST_URL##*/}
DIST_NAME=${ARCHIVE_NAME%-bin.zip}
URL_HASH=$(printf '%s' "$DIST_URL" | sha256sum | awk '{print $1}')
DIST_PARENT="$MAVEN_USER_HOME/wrapper/dists/$DIST_NAME/$URL_HASH"
MAVEN_HOME="$DIST_PARENT/$DIST_NAME"
MAVEN_BIN="$MAVEN_HOME/bin/mvn"

if [ ! -x "$MAVEN_BIN" ]; then
  mkdir -p "$DIST_PARENT"
  TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mvnw.XXXXXX")
  trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM
  ARCHIVE="$TMP_DIR/$ARCHIVE_NAME"

  echo "[INFO] Downloading Maven from $DIST_URL" >&2
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "$DIST_URL" --output "$ARCHIVE"
  elif command -v wget >/dev/null 2>&1; then
    wget --quiet "$DIST_URL" --output-document="$ARCHIVE"
  else
    echo "[ERROR] curl or wget is required to download Maven." >&2
    exit 1
  fi

  if [ -n "$DIST_SHA512" ]; then
    ACTUAL_SHA512=$(sha512sum "$ARCHIVE" | awk '{print $1}')
    if [ "$ACTUAL_SHA512" != "$DIST_SHA512" ]; then
      echo "[ERROR] Maven distribution checksum validation failed." >&2
      exit 1
    fi
  fi

  if command -v unzip >/dev/null 2>&1; then
    unzip -q "$ARCHIVE" -d "$DIST_PARENT"
  else
    echo "[ERROR] unzip is required to install Maven." >&2
    exit 1
  fi
fi

exec "$MAVEN_BIN" "$@"
