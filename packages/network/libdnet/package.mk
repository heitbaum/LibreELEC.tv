# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libdnet"
PKG_VERSION="1.16.1"
PKG_SHA256="b151c4913758ef80daf4558361b4f2680a37b01d59272625bb78c77183062c63"
PKG_LICENSE="BSD"
PKG_SITE="https://github.com/ofalk/libdnet"
PKG_URL="https://github.com/ofalk/libdnet/archive/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libcheck"
PKG_LONGDESC="A simplified, portable interface to several low-level networking routines"
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="+pic"

pre_configure_target() {
  PKG_CONFIGURE_OPTS_TARGET="ac_cv_func_strlcat=no \
                             ac_cv_func_strlcpy=no \
                             --enable-static \
                             --disable-shared \
                             --with-check=${PKG_CONFIG_SYSROOT_DIR}/usr \
                             --disable-python"

  export CFLAGS+=" -I${PKG_BUILD}/include"
}

post_makeinstall_target() {
  cp ${SYSROOT_PREFIX}/usr/bin/dnet-config \
     ${TOOLCHAIN}/bin/dnet-config
}
