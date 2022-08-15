# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libnvme"
PKG_VERSION="1.16.1"
PKG_SHA256="ce1d9d393feb84c4e82ca096db2bdb7dd4a5fd1997d711cc1904796944f2c579"
PKG_LICENSE="GPL"
PKG_SITE="https://nvmexpress.org"
PKG_URL="https://github.com/linux-nvme/libnvme/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain json-c util-linux"
PKG_LONGDESC="C Library for NVM Express on Linux"

PKG_MESON_OPTS_TARGET="-Ddocs=false \
                       -Ddocs-build=false \
                       -Dexamples=false \
                       -Dpython=disabled \
                       -Dopenssl=disabled \
                       -Dtests=false \
                       --default-library=static"
