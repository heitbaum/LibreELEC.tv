# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libheif"
PKG_VERSION="e52035eaeb0697c09f4d70dd52c02281b51f2a0a"
PKG_SHA256="46efbade8a54e97523ed43210cafb344998460910a9118c44a6aafbd8c9737d3"
PKG_LICENSE="LGPLv3"
PKG_SITE="https://www.libde265.org"
PKG_URL="https://github.com/strukturag/libheif/releases/download/v${PKG_VERSION}/libheif-${PKG_VERSION}.tar.gz"
PKG_URL="https://github.com/strukturag/libheif/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libde265 libjpeg-turbo libpng"
PKG_LONGDESC="A HEIF file format decoder and encoder."
PKG_BUILD_FLAGS="+pic"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DWITH_EXAMPLES=OFF \
                       -DWITH_AOM_DECODER=OFF \
                       -DWITH_AOM_ENCODER=OFF"

pre_configure_target() {
  export CXXFLAGS="${CXXFLAGS} -Wno-unused-variable"
}
