# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mpc"
PKG_VERSION="1.3.0"
PKG_SHA256="0e3b12181d37207230f5a7a7ddcfc22abfc5fc9c05825e1a65401a489a432a2a"
PKG_LICENSE="LGPL"
PKG_SITE="https://www.multiprecision.org"
PKG_URL="http://ftpmirror.gnu.org/mpc/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host gmp:host mpfr:host"
PKG_LONGDESC="A C library for the arithmetic of complex numbers with arbitrarily high precision and correct rounding of the result."

PKG_CONFIGURE_OPTS_HOST="--target=${TARGET_NAME} \
                         --enable-static --disable-shared \
                         --with-gmp=${TOOLCHAIN} \
                         --with-mpfr=${TOOLCHAIN}"
