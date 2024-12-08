# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libconfig"
PKG_VERSION="1.8"
PKG_SHA256="22e13253e652ec583ba0dd5b474bd9c7bd85dc724f2deb0d76a6299c421358ef"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/hyperrealm/libconfig"
PKG_URL="https://github.com/hyperrealm/libconfig/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A C/C++ configuration file library."

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DBUILD_EXAMPLES=OFF \
                       -DBUILD_TESTS=OFF"
