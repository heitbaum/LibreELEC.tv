# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="argtable3"
PKG_VERSION="df6b98ea4a16108128300bec20040a25ccab1d2c"
PKG_SHA256="bf5a585a0039413ca68979a05566dc9332c65b9dfc6960ed265b1ba87ad65fa3"
PKG_LICENSE="BSD"
PKG_SITE="https://www.argtable.org"
PKG_URL="https://github.com/argtable/argtable3/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_URL="https://github.com/argtable/argtable3/archive/refs/heads/master.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Argtable is an open source ANSI C library that parses GNU-style command-line options."
PKG_BUILD_FLAGS="-sysroot"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DARGTABLE3_ENABLE_TESTS=OFF \
                       -DARGTABLE3_ENABLE_EXAMPLES=OFF"
