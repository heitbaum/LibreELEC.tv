# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="bemenu"
PKG_VERSION="0.6.17"
PKG_SHA256="d1e16bf2b000d50a5ea2798047250f1d15cc03981c9c08943f0881441e05cbc3"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/Cloudef/bemenu"
PKG_URL="https://github.com/Cloudef/bemenu/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain glib wayland wayland-protocols cairo pango libxkbcommon"
PKG_LONGDESC="Dynamic menu library and client program inspired by dmenu"

PKG_MAKE_OPTS_TARGET="PREFIX=/usr clients wayland"

makeinstall_target(){
  make DESTDIR=${INSTALL} PREFIX=/usr install-libs install-bins install-wayland install-pkgconfig
}

post_makeinstall_target(){
  ln -sf libbemenu.so.${PKG_VERSION} ${INSTALL}/usr/lib/libbemenu.so.0
}
