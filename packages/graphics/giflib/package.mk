# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="giflib"
PKG_VERSION="5.2.2"
PKG_SHA256="be7ffbd057cadebe2aa144542fd90c6838c6a083b5e8a9048b8ee3b66b29d5fb"
PKG_LICENSE="OSS"
PKG_SITE="http://giflib.sourceforge.net/"
PKG_URL="${SOURCEFORGE_SRC}/giflib/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="zlib:host"
PKG_DEPENDS_TARGET="toolchain zlib"
PKG_LONGDESC="giflib: giflib service library"
PKG_TOOLCHAIN="manual"

pre_build_host() {
  mkdir -p ${PKG_BUILD}/.${HOST_NAME}
  cp -r ${PKG_BUILD}/* ${PKG_BUILD}/.${HOST_NAME}
}

make_host() {
  cd ${PKG_BUILD}/.${HOST_NAME}
  make libgif.a CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

makeinstall_host() {
  make install-include PREFIX="${TOOLCHAIN}"
  make install-lib PREFIX="${TOOLCHAIN}"
}

pre_build_target() {
  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}
  cp -r ${PKG_BUILD}/* ${PKG_BUILD}/.${TARGET_NAME}
}

make_target() {
  cd ${PKG_BUILD}/.${TARGET_NAME}
  make libgif.a CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

makeinstall_target() {
  make install-include PREFIX="${SYSROOT_PREFIX}/usr"
  make install-lib PREFIX="${SYSROOT_PREFIX}/usr"
}
