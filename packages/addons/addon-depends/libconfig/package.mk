# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libconfig"
PKG_VERSION="1.8.3"
PKG_SHA256="683f723d647befcdb36e1a4a61a83ae8c89dc7959ca872a7407b6c8152104162"
PKG_LICENSE="LGPL-2.1-or-later"
PKG_SITE="https://github.com/hyperrealm/libconfig"
PKG_URL="https://github.com/hyperrealm/libconfig/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A C/C++ configuration file library."

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DBUILD_EXAMPLES=OFF \
                       -DBUILD_TESTS=OFF"
