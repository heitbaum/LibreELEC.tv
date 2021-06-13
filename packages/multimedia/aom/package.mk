# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="aom"
PKG_VERSION="2929e7809ac84c43363ab6e1bada7302787af9b5" # 3.1.1
PKG_SHA256="edcb58aa47240a10e3d9877469bcac1a3fda0a1be2ad0389fa684934cdfaa29e"
PKG_LICENSE="BSD"
PKG_SITE="https://www.webmproject.org"
PKG_URL="https://repo.or.cz/aom.git/snapshot/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="AV1 Codec Library"

PKG_CMAKE_OPTS_TARGET="-DENABLE_CCACHE=1 \
                       -DENABLE_DOCS=0 \
                       -DENABLE_EXAMPLES=0 \
                       -DENABLE_TESTS=0 \
                       -DENABLE_TOOLS=0"

if [ "${TARGET_ARCH}" = "x86_64" ]; then
  PKG_DEPENDS_TARGET+=" nasm:host"
fi

if ! target_has_feature neon; then
  PKG_CMAKE_OPTS_TARGET+=" -DENABLE_NEON=0 -DENABLE_NEON_ASM=0"
fi
