# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libassuan"
PKG_VERSION="2.5.6"
PKG_SHA256="e9fd27218d5394904e4e39788f9b1742711c3e6b41689a31aa3380bd5aa4f426"
PKG_LICENSE="LGPLv2.1+"
PKG_SITE="https://gnupg.org/software/libassuan/index.html"
PKG_URL="https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain libgpg-error"
PKG_LONGDESC="Libassuan is a small library implementing the so-called Assuan protocol"
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="-sysroot"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --with-gnu-ld \
                           --with-pic \
                           --with-libgpg-error-prefix=${SYSROOT_PREFIX}/usr"
