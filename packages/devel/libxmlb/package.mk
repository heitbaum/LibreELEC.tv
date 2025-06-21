# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libxmlb"
PKG_VERSION="0.3.24"
PKG_SHA256="ded52667aac942bb1ff4d1e977e8274a9432d99033d86918feb82ade82b8e001"
PKG_LICENSE="LGPL-2.1"
PKG_SITE="https://github.com/hughsie/libxmlb"
PKG_URL="https://github.com/hughsie/libxmlb/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain glib"
PKG_LONGDESC="A library to help create and query binary XML blobs"

PKG_MESON_OPTS_TARGET="-Dgtkdoc=false \
                       -Dintrospection=false \
                       -Dtests=false"

#post_makeinstall_target() {
  #safe_remove ${INSTALL}/etc
  #safe_remove ${INSTALL}/usr/lib
#}
