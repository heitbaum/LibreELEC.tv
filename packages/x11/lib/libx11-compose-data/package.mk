# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libx11-compose-data"
PKG_VERSION="1.8.13"
PKG_LICENSE="MIT"
PKG_SITE="https://www.x.org/"
PKG_URL=""
PKG_DEPENDS_UNPACK="libX11"
PKG_DEPENDS_TARGET="toolchain util-macros xtrans libXau libxcb xorgproto"
PKG_LONGDESC="X11 locale/Compose data (dead-key and key-composing tables) for libxkbcommon, without the rest of libX11."
PKG_TOOLCHAIN="autotools"

# libxkbcommon's Compose (dead keys, key composing) loads the X11 locale
# Compose files from /usr/share/X11/locale. On non-x11 display servers libX11
# is not in the image, so build libX11 here but install only its nls locale
# data - the same split Debian ships as libx11-data and Gentoo as
# compose-tables. Keep PKG_VERSION in sync with libX11.

PKG_CONFIGURE_OPTS_TARGET="--disable-loadable-i18n \
                           --disable-loadable-xcursor \
                           --enable-xthreads \
                           --disable-xcms \
                           --enable-xlocale \
                           --disable-xlocaledir \
                           --enable-xkb \
                           --with-keysymdefdir=${SYSROOT_PREFIX}/usr/include/X11 \
                           --disable-xf86bigfont \
                           --enable-malloc0returnsnull \
                           --disable-specs \
                           --without-xmlto \
                           --without-fop \
                           --enable-composecache \
                           --disable-lint-library \
                           --disable-ipv6 \
                           --without-launchd \
                           --without-lint"

unpack() {
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/libX11/libX11-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

make_target() {
  make -C nls
}

makeinstall_target() {
  make -C nls install DESTDIR="${INSTALL}"
}
