# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nqptp"
PKG_VERSION="1.2.6"
PKG_SHA256="26f65165c3545a6cee0b9846b47ce52a015fcd8ec153fe16997d36f61c88029e"
PKG_REV="1"
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://github.com/mikebrady/nqptp"
PKG_URL="https://github.com/mikebrady/nqptp/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="service"
PKG_SHORTDESC="Not Quite PTP"
PKG_LONGDESC="Not Quite PTP"
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="-sysroot -cfg-libs"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="nqptp"
PKG_ADDON_TYPE="xbmc.service"

PKG_CONFIGURE_OPTS_TARGET="--with-systemd-startup"

addon() {
  mkdir -p "${ADDON_BUILD}/${PKG_ADDON_ID}/bin"
  cp ${PKG_INSTALL}/usr/bin/nqptp \
     "${ADDON_BUILD}/${PKG_ADDON_ID}/bin"
}
