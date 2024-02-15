# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nvme-cli"
PKG_VERSION="2.8"
PKG_SHA256="0743d9188792a87d39187ae5e5cb31e8f46cca8c6f100547c50ec0dd659d2531"
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
