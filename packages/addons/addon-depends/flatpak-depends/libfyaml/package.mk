# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libfyaml"
PKG_VERSION="25540e1ac4beb16bdf9e18441abc06071d271896"
PKG_SHA256="38f6210984639a17f412f8ab50dc982c57e10873f86a51d0e6e8a03e3ee80874"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/pantoniou/libfyaml"
PKG_URL="https://github.com/pantoniou/libfyaml/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Fully feature complete YAML parser and emitter"
PKG_BUILD_FLAGS="+pic:host +pic -sysroot"

PKG_CMAKE_OPTS_HOST="-DBUILD_SHARED_LIBS=OFF \
                     -DENABLE_NETWORK=OFF \
                     -DBUILD_TESTING=OFF \
                     -DENABLE_LIBCLANG=OFF"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF \
                       -DENABLE_NETWORK=OFF \
                       -DBUILD_TESTING=OFF \
                       -DENABLE_LIBCLANG=OFF"
