# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libjcat"
PKG_VERSION="0.2.5"
PKG_SHA256="066e402168c51bffddcf325190e5901402b266fbda2a4eed772fd06a88b941bf"
PKG_LICENSE="LGPL-2.1"
PKG_SITE="https://github.com/hughsie/libjcat"
PKG_URL="https://github.com/hughsie/libjcat/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain gnutls gpgme json-glib"
PKG_LONGDESC="Library for reading and writing Jcat files"

PKG_MESON_OPTS_TARGET="-Dgtkdoc=false \
                       -Dintrospection=false \
                       -Dtests=false"

#post_makeinstall_target() {
  #safe_remove ${INSTALL}/etc
  #safe_remove ${INSTALL}/usr/lib
#}
