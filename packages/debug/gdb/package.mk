# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gdb"
PKG_VERSION="16.0.50.20241217"
PKG_SHA256="47006325c239cebf068222571adcba01508f814c3302faf0fbc42484d9bee02b"
PKG_LICENSE="GPL"
PKG_SITE="https://www.gnu.org/software/gdb/"
PKG_URL="https://ftp.gnu.org/gnu/gdb/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_URL="https://sourceware.org/pub/gdb/snapshots/current/gdb-weekly-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain expat gmp mpfr ncurses zlib"
PKG_DEPENDS_HOST="toolchain:host expat:host gmp:host mpfr:host ncurses:host zlib:host"
PKG_LONGDESC="GNU Project debugger, allows you to see what is going on inside another program while it executes."
PKG_BUILD_FLAGS="+size"

PKG_CONFIGURE_OPTS_COMMON="bash_cv_have_mbstate_t=set \
                           --disable-shared \
                           --enable-static \
                           --with-auto-load-safe-path=/ \
                           --with-python=no \
                           --with-guile=no \
                           --with-intel-pt=no \
                           --with-babeltrace=no \
                           --with-expat=yes \
                           --disable-source-highlight \
                           --disable-nls \
                           --disable-rpath \
                           --disable-sim \
                           --without-x \
                           --disable-tui \
                           --disable-libada \
                           --without-lzma \
                           --disable-libquadmath \
                           --disable-libquadmath-support \
                           --enable-libada \
                           --enable-libssp \
                           --disable-werror"

PKG_CONFIGURE_OPTS_TARGET="${PKG_CONFIGURE_OPTS_COMMON} \
                           --with-libexpat-prefix=${SYSROOT_PREFIX}/usr \
                           --with-libgmp-prefix=${SYSROOT_PREFIX}/usr"

PKG_CONFIGURE_OPTS_HOST="${PKG_CONFIGURE_OPTS_COMMON} \
                         --target=${TARGET_NAME}"

pre_configure_target() {
  CC_FOR_BUILD="${HOST_CC}"
  CFLAGS_FOR_BUILD="${HOST_CFLAGS}"
}

makeinstall_target() {
  make DESTDIR=${INSTALL} install
}

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/share/gdb/python
}
