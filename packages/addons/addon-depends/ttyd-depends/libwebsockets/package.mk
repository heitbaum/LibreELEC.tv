# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libwebsockets"
PKG_VERSION="4.3.4"
PKG_SHA256="896b36aa063b4d05865f9ffee4404b26d4c2d3e2ba17b0b69f021b615377845e"
PKG_LICENSE="MIT"
PKG_SITE="https://libwebsockets.org"
PKG_URL="https://github.com/warmcat/libwebsockets/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain openssl json-c libuv"
PKG_LONGDESC="Library for implementing network protocols with a tiny footprint."

PKG_CMAKE_OPTS_TARGET="-DLWS_WITH_LIBUV=ON \
                       -DLWS_WITHOUT_TESTAPPS=ON"
