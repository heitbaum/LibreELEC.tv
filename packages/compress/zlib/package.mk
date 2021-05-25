# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="zlib"
PKG_VERSION="2.0.3"
PKG_SHA256="30305bd1551e3454bddf574f9863caf7137dde0fdbd4dcd7094eacfbb23955a0"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/zlib-ng/zlib-ng"
PKG_URL="https://github.com/zlib-ng/zlib-ng/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="cmake:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="zlib data compression library for the next generation systems"
PKG_TOOLCHAIN="cmake-make"

PKG_CMAKE_OPTS_HOST="-DZLIB_COMPAT=ON"

PKG_CMAKE_OPTS_TARGET="-DZLIB_COMPAT=ON"
