# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nvme-cli"
PKG_VERSION="2.7.1"
PKG_SHA256="4c69d0f3c8b553110d0f63f5876d56627abd2d9f5d3904e2480cedd03cb15654"
PKG_LICENSE="GPL"
PKG_SITE="https://nvmexpress.org"
PKG_URL="https://github.com/linux-nvme/nvme-cli/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain json-c libnvme util-linux zlib"
PKG_LONGDESC="NVMe management command line interface"

PKG_MESON_OPTS_TARGET="-Ddocs=false \
                       -Ddocs-build=false"

post_makeinstall_target() {
  safe_remove ${INSTALL}/etc
  safe_remove ${INSTALL}/usr/lib
}
