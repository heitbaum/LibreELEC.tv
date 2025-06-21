# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libxmlb"
PKG_VERSION="0.3.22"
PKG_SHA256="f3c46e85588145a1a86731c77824ec343444265a457647189a43b71941b20fa0"
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
