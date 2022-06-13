# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mmc-utils"
PKG_VERSION="b7e4d5a6ae9942d26a11de9b05ae7d52c0802802" # 2022-04-26
PKG_SHA256="219f8d07957871644fe256f806fce22eb3d0e7ac58dc8b7607308405a3b0da37"
PKG_LICENSE="GPL"
PKG_SITE="https://www.kernel.org/doc/html/latest/driver-api/mmc/mmc-tools.html"
PKG_URL="https://git.kernel.org/pub/scm/utils/mmc/mmc-utils.git/snapshot/mmc-utils-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Configure MMC storage devices from userspace."
PKG_BUILD_FLAGS="-sysroot"
