# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libuv"
PKG_VERSION="1.50.0"
PKG_SHA256="b1ec56444ee3f1e10c8bd3eed16ba47016ed0b94fe42137435aaf2e0bd574579"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/libuv/libuv"
PKG_URL="https://github.com/libuv/libuv/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Multi-platform support library with a focus on asynchronous I/O"

PKG_CMAKE_OPTS_TARGET="-DLIBUV_BUILD_TESTS=OFF"
