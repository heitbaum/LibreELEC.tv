# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libimobiledevice"
PKG_VERSION="eda2c5ea71829f11d69342e6858d09aa53943938"
PKG_SHA256="1ec68277ee98e9e0694202479b9495f2e74689370efb36535fe57b3f17c6b3f8"
PKG_LICENSE="GPL"
PKG_SITE="http://www.libimobiledevice.org"
PKG_URL="https://github.com/libimobiledevice/libimobiledevice/releases/download/${PKG_VERSION}/libimobiledevice-${PKG_VERSION}.tar.bz2"
PKG_URL="https://github.com/libimobiledevice/libimobiledevice/archive/${PKG_VERSION}/libimobiledevice-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libimobiledevice-glue libplist libusbmuxd openssl"
PKG_LONGDESC="A cross-platform software library that talks the protocols to support Apple devices."
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --without-cython \
                           --disable-largefile"

post_configure_target() {
  libtool_remove_rpath libtool
}
