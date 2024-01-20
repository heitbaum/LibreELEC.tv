# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="argtable3"
PKG_VERSION="3.2.2.f25c624"
PKG_SHA256="a5c66d819fa0be0435f37ed2fb3f23e371091722ff74219de97b65f6b9914e51"
PKG_LICENSE="BSD"
PKG_SITE="https://www.argtable.org"
PKG_URL="https://github.com/argtable/argtable3/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Argtable is an open source ANSI C library that parses GNU-style command-line options."
PKG_BUILD_FLAGS="-sysroot"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DARGTABLE3_ENABLE_TESTS=OFF \
                       -DARGTABLE3_ENABLE_EXAMPLES=OFF"
