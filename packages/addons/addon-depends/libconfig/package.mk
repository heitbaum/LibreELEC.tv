# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libconfig"
PKG_VERSION="e6b9fd1eac1d4b5cdaeda9d5829b587859211518"
PKG_SHA256="5a924c30c2d43b7f2a4576363a617d8809b4c91771fb959b7848c420d9c29aee"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/hyperrealm/libconfig"
PKG_URL="https://github.com/hyperrealm/libconfig/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A C/C++ configuration file library."
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --disable-doc \
                           --disable-examples \
                           --disable-tests \
                           --with-sysroot=${SYSROOT_PREFIX}"

pre_configure_target() {
  cd ..
  rm -rf .${TARGET_NAME}
  rm lib/grammar.c
}
