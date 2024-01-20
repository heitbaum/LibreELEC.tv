# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="argtable3"
PKG_VERSION="3.3.1"
PKG_SHA256="c08bca4b88ddb9234726b75455b3b1670d7c864d8daf198eaa7a3b4d41addf2c"
PKG_LICENSE="BSD"
PKG_SITE="https://www.argtable.org"
PKG_URL="https://github.com/argtable/argtable3/releases/download/v${PKG_VERSION}/argtable-v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Argtable is an open source ANSI C library that parses GNU-style command-line options."
PKG_BUILD_FLAGS="-sysroot"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DARGTABLE3_ENABLE_TESTS=OFF \
                       -DARGTABLE3_ENABLE_EXAMPLES=OFF"
