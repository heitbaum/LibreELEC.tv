# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libfyaml"
PKG_VERSION="v1.0.0-beta2"
PKG_SHA256="fc621487a1f665d7e62a11e722fd30b8f76b6bcaeb9ed5e1648f2c1db73ccd75"
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
