#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-only

# Sync the LibreELEC sources/ download cache from the build host to this machine.
#
# Direction : pull  (build host -> here)
# Mode      : mirror (--delete) -- the local sources/ becomes an exact copy of
#             the remote, deleting any local files not present on the host.
#
# Overridable via environment:
#   BUILD_HOST   ssh target             (default: root@192.168.42.63)
#   REMOTE_DIR   remote sources/ path   (default: /var/media/DATA/home-rudi/LibreELEC.tv/sources/)
#   LOCAL_DIR    local sources/ path    (default: <this repo>/sources/)
#
# Extra rsync args are passed through, e.g. a dry run:
#   ./sync-sources.sh -n

set -euo pipefail

BUILD_HOST="${BUILD_HOST:-root@192.168.42.63}"
REMOTE_DIR="${REMOTE_DIR:-/var/media/DATA/home-rudi/LibreELEC.tv/sources/}"

# Local sources dir lives beside this script (repo root), unless overridden.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="${LOCAL_DIR:-${SCRIPT_DIR}/sources/}"

# Prefer rsync on PATH; fall back to a MSYS2 install (Git Bash can't see it).
RSYNC="$(command -v rsync 2>/dev/null || true)"
if [ -z "${RSYNC}" ]; then
  for c in /c/msys64/usr/bin/rsync.exe "${LOCALAPPDATA:-}/Programs/MSYS2/usr/bin/rsync.exe"; do
    [ -x "${c}" ] && { RSYNC="${c}"; break; }
  done
fi
if [ -z "${RSYNC}" ]; then
  echo "error: rsync not found on this machine." >&2
  echo "  MSYS2:  pacman -S rsync   (then it's picked up automatically)" >&2
  echo "  or install cwRsync and put rsync.exe on PATH." >&2
  exit 1
fi

# rsync must spawn an ssh from its OWN runtime -- mixing MSYS2 rsync with Git's
# ssh gives "dup() in/out/err failed". Prefer the ssh next to the chosen rsync.
SSH_BIN="ssh"
_rsync_dir="$(dirname "${RSYNC}")"
[ -x "${_rsync_dir}/ssh.exe" ] && SSH_BIN="${_rsync_dir}/ssh.exe"
[ -x "${_rsync_dir}/ssh" ] && SSH_BIN="${_rsync_dir}/ssh"

# The MSYS2 ssh resolves its own POSIX home (/home/<user>), ignoring the Git
# Bash $HOME, so it can't see this shell's known_hosts. Pin the file explicitly
# and auto-record unknown host keys (no tty for the accept prompt via rsync).
KNOWN_HOSTS="${KNOWN_HOSTS:-${HOME}/.ssh/known_hosts}"
mkdir -p "$(dirname "${KNOWN_HOSTS}")"
SSH_CMD="${SSH_BIN} -o UserKnownHostsFile=${KNOWN_HOSTS} -o StrictHostKeyChecking=accept-new"

# Same home mismatch applies to the private key -- pin it if present.
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_ed25519}"
[ -f "${SSH_KEY}" ] && SSH_CMD="${SSH_CMD} -o IdentityFile=${SSH_KEY} -o IdentitiesOnly=yes"

# Trailing slashes are load-bearing: sync the *contents* of the remote sources/
# into the local sources/ (not into a nested sources/sources/).
mkdir -p "${LOCAL_DIR}"

echo "Pull (mirror): ${BUILD_HOST}:${REMOTE_DIR}"
echo "            -> ${LOCAL_DIR}"

exec "${RSYNC}" -avh --delete --progress \
  -e "${SSH_CMD}" \
  "${BUILD_HOST}:${REMOTE_DIR}" "${LOCAL_DIR}" "$@"
