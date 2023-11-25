# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="duktape"
PKG_VERSION="2.7.0"
PKG_SHA256="90f8d2fa8b5567c6899830ddef2c03f3c27960b11aca222fa17aa7ac613c2890"
PKG_LICENSE="MIT"
PKG_SITE="https://duktape.org"
PKG_URL="https://duktape.org/duktape-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="embeddable Javascript engine with a focus on portability and compact footprint"
PKG_TOOLCHAIN="manual"
PKG_BUILD_FLAGS="-sysroot"

make_target() {
  INSTALL_PREFIX=/usr make -f Makefile.sharedlibrary
}

makeinstall_target() {
  INSTALL_PREFIX=${INSTALL}/usr make -f Makefile.sharedlibrary install
}
