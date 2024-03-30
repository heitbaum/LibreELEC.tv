# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="xz"
PKG_VERSION="5.4.7"
PKG_SHA256="016182c70bb5c7c9eb3465030e3a7f6baa25e17b0e8c0afe92772e6021843ce2"
PKG_LICENSE="GPL"
PKG_SITE="https://tukaani.org/xz/"
PKG_URL="https://github.com/tukaani-project/xz/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="autoconf:host gcc:host"
PKG_LONGDESC="A free general-purpose data compression software with high compression ratio."
PKG_BUILD_FLAGS="+pic -sysroot"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_TARGET="--disable-shared --enable-static \
                           --enable-symbol-versions=no"

post_makeinstall_target() {
  echo rm -rf ${INSTALL}
}
