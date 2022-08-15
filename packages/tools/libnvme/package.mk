# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libnvme"
PKG_VERSION="1.1"
PKG_SHA256="d000181356513733671409c747c88826155b60f45f76e7289d6bbf27a8f851b0"
PKG_LICENSE="GPL"
PKG_SITE="https://nvmexpress.org"
PKG_URL="https://github.com/linux-nvme/libnvme/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain json-c util-linux"
PKG_LONGDESC="C Library for NVM Express on Linux"

PKG_MESON_OPTS_TARGET="-Ddocs=false \
                       -Ddocs-build=false \
                       -Dpython=false \
                       -Dopenssl=disabled \
                       --default-library=static"
