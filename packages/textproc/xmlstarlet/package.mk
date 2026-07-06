# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="xmlstarlet"
PKG_VERSION="c99e79b7b4058d862b1be5fbbcd8049075610618"
PKG_SHA256="d90e05287f765061a021baff875c15b0839b7184cdd0a4cc6e614ed6e6cb8a8a"
PKG_LICENSE="MIT"
PKG_SITE="https://xmlstarlet.github.io/"
PKG_URL="https://github.com/xmlstarlet/xmlstarlet/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="libxml2:host libxslt:host"
PKG_DEPENDS_TARGET="toolchain libxml2 libxslt"
PKG_LONGDESC="XMLStarlet is a command-line XML utility which allows the modification and validation of XML documents."
PKG_BUILD_FLAGS="-cfg-libs -cfg-libs:host"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_HOST="  ac_cv_func_malloc_0_nonnull=yes \
                           ac_cv_func_realloc_0_nonnull=yes \
                           LIBXML_CONFIG=${TOOLCHAIN}/bin/xml2-config \
                           LIBXSLT_CONFIG=${TOOLCHAIN}/bin/xslt-config \
                           --with-libxml-include-prefix=${TOOLCHAIN}/include/libxml2 \
                           --with-libxml-libs-prefix=${TOOLCHAIN}/lib \
                           --with-libxslt-include-prefix=${TOOLCHAIN}/include \
                           --with-libxslt-libs-prefix=${TOOLCHAIN}/lib \
                           --disable-build-docs"

PKG_CONFIGURE_OPTS_TARGET="ac_cv_func_malloc_0_nonnull=yes \
                           ac_cv_func_realloc_0_nonnull=yes \
                           LIBXML_CONFIG=${SYSROOT_PREFIX}/usr/bin/xml2-config \
                           LIBXSLT_CONFIG=${SYSROOT_PREFIX}/usr/bin/xslt-config \
                           --with-libxml-include-prefix=${SYSROOT_PREFIX}/usr/include/libxml2 \
                           --with-libxml-libs-prefix=${SYSROOT_PREFIX}/usr/lib \
                           --with-libxslt-include-prefix=${SYSROOT_PREFIX}/usr/include \
                           --with-libxslt-libs-prefix=${SYSROOT_PREFIX}/usr/lib \
                           --disable-build-docs"

post_configure_host() {
  PKG_MAKE_OPTS_HOST+=" man_MANS= dist_doc_DATA="
  PKG_MAKEINSTALL_OPTS_HOST+=" man_MANS= dist_doc_DATA="
}

post_configure_target() {
  PKG_MAKE_OPTS_TARGET+=" man_MANS= dist_doc_DATA="
  PKG_MAKEINSTALL_OPTS_TARGET+=" man_MANS= dist_doc_DATA="
}

post_makeinstall_host() {
  ln -sf xml ${TOOLCHAIN}/bin/xmlstarlet
}

post_makeinstall_target() {
  ln -sf xml ${INSTALL}/usr/bin/xmlstarlet
}
