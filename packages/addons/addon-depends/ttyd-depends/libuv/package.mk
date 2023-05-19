# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libuv"
PKG_VERSION="1.45.0"
PKG_SHA256="458e34d5ef7f3c0394a2bfd8c39d757cb1553baa5959b9b4b45df63aa027a228"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/libuv/libuv"
PKG_URL="https://github.com/libuv/libuv/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Multi-platform support library with a focus on asynchronous I/O"

PKG_CMAKE_OPTS_TARGET="-DLIBUV_BUILD_TESTS=OFF"
