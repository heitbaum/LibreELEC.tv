# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="zlib"
PKG_VERSION="2.0.5"
PKG_SHA256="eca3fe72aea7036c31d00ca120493923c4d5b99fe02e6d3322f7c88dbdcd0085"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/zlib-ng/zlib-ng"
PKG_URL="https://github.com/zlib-ng/zlib-ng/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host cmake:host"
PKG_DEPENDS_TARGET="cmake:host gcc:host"
PKG_LONGDESC="zlib data compression library for the next generation systems"
PKG_TOOLCHAIN="cmake-make"

PKG_CMAKE_OPTS_HOST="-DZLIB_COMPAT=ON"

PKG_CMAKE_OPTS_TARGET="-DZLIB_COMPAT=ON"
