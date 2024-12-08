# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libconfig"
PKG_VERSION="ca412e1d54d7c723028034d013a4f05f048b23c1"
PKG_SHA256="bc51d74b1799b663c164902bd49990f653340a1e89d9b0377a66cedc3f84cc77"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/hyperrealm/libconfig"
PKG_URL="https://github.com/hyperrealm/libconfig/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A C/C++ configuration file library."

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DBUILD_EXAMPLES=OFF \
                       -DBUILD_TESTS=OFF"
