# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="dislocker"
PKG_VERSION="0.7.3"
PKG_SHA256="8d5275577c44f2bd87f6e05dd61971a71c0e56a9cbedf000bd38deadd8b6c1e6"
PKG_LICENSE="GPL2"
PKG_SITE="https://github.com/Aorimn/dislocker"
PKG_URL="https://github.com/Aorimn/dislocker/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain fuse libmbedtls"
#PKG_DEPENDS_CONFIG="libmbedtls"
PKG_LONGDESC="FUSE driver to read/write Windows' BitLocker-ed volumes."
PKG_BUILD_FLAGS="-sysroot"

PKG_CMAKE_OPTS_TARGET="-DCMAKE_INSTALL_PREFIX=/usr \
                       -DLIB_INSTALL_DIR=/usr/lib \
		       -DPOLARSSL_INCLUDE_DIRS=$(get_install_dir libmbedtls)/usr/include \
		       -DPOLARSSL_LIBRARIES=$(get_install_dir libmbedtls)/usr/lib/libmbedcrypto.so \
                       -DCMAKE_SKIP_RPATH=ON \
                       -DWITH_RUBY=OFF"

pre_configure_target() {
  export WITH_RUBY="OFF"
}
