# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nvtop"
PKG_VERSION="3.2.0"
PKG_SHA256="d26df685455023cedc4dda033862dcddb67402fbdb685da70da78492f73c41d0"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://github.com/Syllo/nvtop"
PKG_URL="https://github.com/Syllo/nvtop/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libdrm ncurses systemd"
PKG_LONGDESC="GPU & Accelerator process monitoring for AMD, Apple, Huawei, Intel, NVIDIA and Qualcomm."

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/share
}
