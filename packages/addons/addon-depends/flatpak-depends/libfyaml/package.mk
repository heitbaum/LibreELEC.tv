# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libfyaml"
PKG_VERSION="1.0.0-alpha5"
PKG_SHA256="aa2eada2bdddc17792708c108ed947633da21fde3124c3ebc764dfea6c257566"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/pantoniou/libfyaml"
PKG_URL="https://github.com/pantoniou/libfyaml/archive/v${PKG_VERSION}.tar.gz"
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
