# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="xz"
PKG_VERSION="5.4.6"
PKG_SHA256="b92d4e3a438affcf13362a1305cd9d94ed47ddda22e456a42791e630a5644f5c"
PKG_LICENSE="GPL"
PKG_SITE="https://tukaani.org/xz/"
PKG_URL="https://github.com/tukaani-project/xz/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A free general-purpose data compression software with high compression ratio."
PKG_BUILD_FLAGS="+pic -sysroot"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_TARGET="--disable-shared --enable-static \
                           --enable-symbol-versions=no"
