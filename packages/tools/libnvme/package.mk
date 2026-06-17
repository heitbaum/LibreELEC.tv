# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libnvme"
PKG_VERSION="1.16.2"
PKG_SHA256="1d850d5a871559abf641d6e6b63bb86047e4cb26f3ad144597c2c64b3cff7231"
PKG_LICENSE="LGPL-2.1-or-later"
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
