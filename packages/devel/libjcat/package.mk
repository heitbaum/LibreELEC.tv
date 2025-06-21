# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libjcat"
PKG_VERSION="0.2.3"
PKG_SHA256="f2f115aad8a8f16b8dde1ed55de7abacb91d0878539aa29b2b60854b499db639"
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
