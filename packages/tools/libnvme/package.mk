# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libnvme"
PKG_VERSION="1.7.1"
PKG_SHA256="e9c3ad59c068788faf0f0af4296f92f8ce410d12749f0f35a541d6a21e630393"
PKG_LICENSE="GPL"
PKG_SITE="https://nvmexpress.org"
PKG_URL="https://github.com/linux-nvme/libnvme/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain json-c util-linux"
PKG_LONGDESC="C Library for NVM Express on Linux"

PKG_MESON_OPTS_TARGET="-Ddocs=false \
                       -Ddocs-build=false \
                       -Dpython=disabled \
                       -Dopenssl=disabled \
                       --default-library=static"