# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libfyaml"
PKG_VERSION="v1.0.0-alpha7"
PKG_SHA256="ce07e69b743e1fbdb0752d62dc6eb5e27ad1bb7396cb1ffd0fad11c049da6be1"
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
