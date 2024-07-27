# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="xz"
PKG_VERSION="5.6.4"
PKG_SHA256="829ccfe79d769748f7557e7a4429a64d06858e27e1e362e25d01ab7b931d9c95"
PKG_LICENSE="GPL"
PKG_SITE="https://tukaani.org/xz/"
PKG_URL="https://github.com/tukaani-project/xz/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="autotools:host gcc:host"
PKG_LONGDESC="A free general-purpose data compression software with high compression ratio."
PKG_BUILD_FLAGS="+pic -sysroot"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --disable-doc \
                           --disable-lzmadec \
                           --disable-lzmainfo \
                           --disable-lzma-links \
                           --disable-scripts \
                           --disable-xz \
                           --disable-xzdec \
                           --enable-symbol-versions=no"
