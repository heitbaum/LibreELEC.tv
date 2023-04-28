# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libusbmuxd"
PKG_VERSION="3.0.2"
PKG_SHA256="5da7b60d0fd78f8e1c0f68b7fceafde373a40a2791af20cdcce639f1174abad2"
PKG_LICENSE="GPL"
PKG_SITE="http://www.libimobiledevice.org"
PKG_URL="https://github.com/libimobiledevice/libusbmuxd/releases/download/${PKG_VERSION}/libusbmuxd-${PKG_VERSION}.tar.bz2"
PKG_URL="https://github.com/libimobiledevice/libusbmuxd/archive/refs/heads/master.tar.gz"
PKG_DEPENDS_TARGET="toolchain libimobiledevice-glue libplist"
PKG_LONGDESC="A USB multiplex daemon."
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="ac_cv_func_malloc_0_nonnull=yes \
                           ac_cv_func_realloc_0_nonnull=yes \
                           --enable-static \
                           --disable-shared"

post_configure_target() {
  libtool_remove_rpath libtool
}
