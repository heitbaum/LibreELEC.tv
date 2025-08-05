# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libmbedtls"
PKG_VERSION="2.28.10"
PKG_SHA256="0f2e0525903a89ae1d39ce439d858be66933bda54c5b6102b72a29ed8fe7c088"
PKG_LICENSE="GPL"
PKG_SITE="https://www.trustedfirmware.org/projects/mbed-tls/"
PKG_URL="https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="mbed TLS (formerly known as PolarSSL) is a lean open source crypto library for providing SSL and TLS support."
PKG_BUILD_FLAGS="-sysroot"

PKG_CMAKE_OPTS_TARGET="-DCMAKE_INSTALL_PREFIX=/usr \
                       -DUSE_SHARED_MBEDTLS_LIBRARY=On"
