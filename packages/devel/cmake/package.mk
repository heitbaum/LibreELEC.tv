# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="cmake"
PKG_VERSION="3.28.0-rc5"
PKG_SHA256="f8bffee43c050771c5ba5a8a150b96addfaf273107db08d608bcd744cdbb955a"
PKG_LICENSE="BSD"
PKG_SITE="https://cmake.org/"
PKG_URL="https://cmake.org/files/v$(get_pkg_version_maj_min | cut -f 1 -d -)/cmake-${PKG_VERSION}.tar.gz"
PKG_URL="https://cmake.org/files/v3.28/cmake-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="pkg-config:host"
PKG_LONGDESC="A cross-platform, open-source make system."
PKG_TOOLCHAIN="configure"
PKG_BUILD_FLAGS="+local-cc"

configure_host() {
  ../configure --prefix=${TOOLCHAIN} \
               --no-qt-gui --no-system-libs \
               -- \
               -DCMAKE_C_FLAGS="-O2 -Wall -pipe -Wno-format-security" \
               -DCMAKE_CXX_FLAGS="-O2 -Wall -pipe -Wno-format-security" \
               -DCMAKE_EXE_LINKER_FLAGS="${HOST_LDFLAGS}" \
               -DCMAKE_USE_OPENSSL=OFF \
               -DBUILD_CursesDialog=0
}
