# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gettext-reusable"
PKG_LICENSE="GPL-3.0-or-later AND LGPL-2.1-or-later"
PKG_SITE="https://www.gnu.org/s/gettext/"
PKG_LONGDESC="Prebuilt gettext:host."
PKG_TOOLCHAIN="manual"

# gettext owns the naming and decides whether to depend on this package, and must
# never source it in turn
PKG_VERSION="$(get_pkg_variable gettext PKG_REUSABLE_VERSION)"
PKG_SOURCE_NAME="$(get_pkg_variable gettext PKG_REUSABLE_SOURCE_NAME)"

# only probe when asked to, and leave PKG_URL unset when there is nothing to get
# so that scripts/get does not retry a missing archive
if [ "${USE_REUSABLE}" = "yes" -o "${USE_REUSABLE}" = "preferred" ]; then
  PKG_URL="$(get_pkg_variable gettext PKG_REUSABLE_URL)"
  PKG_SHA256="$(get_reusable_sha256 ${PKG_NAME} ${PKG_SOURCE_NAME} ${PKG_URL})"
  if [ -z "${PKG_SHA256}" ]; then
    PKG_URL=""
  fi
fi

# the archive name already covers what it is built from, so rebuild when a
# different archive is chosen
PKG_STAMP="${PKG_SOURCE_NAME} ${PKG_SHA256}"

unpack() {
  [ -f "${SOURCES}/${PKG_NAME}/${PKG_SOURCE_NAME}" ] ||
    die "${PKG_SOURCE_NAME} is not available, set USE_REUSABLE=preferred or no"

  mkdir -p "${PKG_BUILD}"
  tar --strip-components=1 -xf "${SOURCES}/${PKG_NAME}/${PKG_SOURCE_NAME}" -C "${PKG_BUILD}"
}

makeinstall_host() {
  reusable_install "${PKG_BUILD}"
}
