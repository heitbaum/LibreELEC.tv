# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nvtop"
PKG_VERSION="3.4.0"
PKG_SHA256="7979f425dc2b748ff191e3999a0994af6154795e0e8640fae1e177684a296e08"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://github.com/Syllo/nvtop"
PKG_URL="https://github.com/Syllo/nvtop/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libdrm ncurses systemd"
PKG_LONGDESC="GPU & Accelerator process monitoring for AMD, Apple, Huawei, Intel, NVIDIA and Qualcomm."

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/share
}
