# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nvme-cli"
PKG_VERSION="2.4"
PKG_SHA256="7f80102a933e3bf46f4f2089cad119c827a363478235f66b89ddaad9ca57d019"
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
