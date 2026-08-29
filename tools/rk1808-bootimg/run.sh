#!/bin/sh
# Run a command in the build container with the tools this project needs.
# Once the list settles these go into the docker image and the apt line goes.
#
#   IMAGE   container to run in
#   ROOT    directory bind mounted into the container, and the work directory
set -e
IMAGE="${IMAGE:-resolute:latest}"
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
# gcc-11 for the 4.4 tree, the distro default for 6.1 - 6.1 Kconfig checks
# $(CROSS_COMPILE)gcc directly, so the unversioned one has to exist too
# one line: a newline here ends the apt-get command and the rest becomes a
# command of its own, which fails silently and leaves the tools missing
TOOLS="cpio device-tree-compiler file xz-utils bc bison flex libssl-dev gcc-11-aarch64-linux-gnu gcc-aarch64-linux-gnu gdb-multiarch"

docker run --rm --user root -v "$ROOT:$ROOT" -w "$ROOT" "$IMAGE" bash -c "
  if ! command -v cpio >/dev/null 2>&1 || ! command -v aarch64-linux-gnu-gcc-11 >/dev/null 2>&1 || ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq $TOOLS >/dev/null 2>&1
  fi
  $*
"
