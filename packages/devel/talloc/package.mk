# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="talloc"
PKG_VERSION="2.4.2"
PKG_SHA256="85ecf9e465e20f98f9950a52e9a411e14320bc555fa257d87697b7e7a9b1d8a6"
PKG_LICENSE="LGPL-3.0-or-later"
PKG_SITE="https://talloc.samba.org/"
PKG_URL="https://www.samba.org/ftp/talloc/talloc-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="talloc is a hierarchical, reference counted memory pool system with destructors"
PKG_BUILD_FLAGS="-cfg-libs"

PKG_CONFIGURE_OPTS_TARGET="--cross-compile"

pre_configure_target() {
  # talloc uses its own build directory
  cd ${PKG_BUILD}
    rm -rf .${TARGET_NAME}
}
