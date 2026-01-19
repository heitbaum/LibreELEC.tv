# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nvtop"
PKG_VERSION="3.3.1"
PKG_SHA256="8318aff973e0850bea4b9d7d313c513206cdc9b8387e8441681e84ac2bc0e980"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://github.com/Syllo/nvtop"
PKG_URL="https://github.com/Syllo/nvtop/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libdrm ncurses systemd"
PKG_LONGDESC="GPU & Accelerator process monitoring for AMD, Apple, Huawei, Intel, NVIDIA and Qualcomm."

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/share
}
