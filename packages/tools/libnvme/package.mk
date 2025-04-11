# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libnvme"
PKG_VERSION="1.13"
PKG_SHA256="f083c21f525644a2bcca6d367d96fab813de880cba9f1746a850f3a8692a5980"
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
