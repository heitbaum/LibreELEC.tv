# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="argtable3"
PKG_VERSION="3.3.0.116da6c"
PKG_SHA256="21d653eaab4b9dede76ceb0cb4e8878cf5cadb48ef9180c6a4d1a5cef1549e65"
PKG_LICENSE="BSD"
PKG_SITE="https://www.argtable.org"
PKG_URL="https://github.com/argtable/argtable3/releases/download/v${PKG_VERSION}/argtable-v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Argtable is an open source ANSI C library that parses GNU-style command-line options."
PKG_BUILD_FLAGS="-sysroot"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DARGTABLE3_ENABLE_TESTS=OFF \
                       -DARGTABLE3_ENABLE_EXAMPLES=OFF"
