# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="diffutils"
PKG_VERSION="3.12"
PKG_SHA256="7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd"
PKG_LICENSE="GPL"
PKG_SITE="http://www.gnu.org/software/diffutils/"
PKG_URL="https://ftpmirror.gnu.org/diffutils/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A package of several programs related to finding differences between files."
PKG_BUILD_FLAGS="-sysroot -cfg-libs"

PKG_CONFIGURE_OPTS_TARGET="--disable-nls \
        --without-libsigsegv-prefix \
        --without-libiconv-prefix \
        --without-libintl-prefix"
