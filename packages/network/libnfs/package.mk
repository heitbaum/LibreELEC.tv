# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libnfs"
PKG_VERSION="6.0.2"
PKG_SHA256="4e5459cc3e0242447879004e9ad28286d4d27daa42cbdcde423248fad911e747"
PKG_LICENSE="LGPL2.1+"
PKG_SITE="https://github.com/sahlberg/libnfs"
PKG_URL="https://github.com/sahlberg/libnfs/archive/libnfs-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A client library for accessing NFS shares over a network."

PKG_CMAKE_OPTS_TARGET="-DENABLE_DOCUMENTATION=OFF \
                       -DENABLE_EXAMPLES=OFF \
                       --without-libkrb5 \
                       -DENABLE_TESTS=OFF \
                       -DENABLE_UTILS=ON"

pre_configure_target() {
  export CFLAGS="${CFLAGS} -D_FILE_OFFSET_BITS=64"
}
