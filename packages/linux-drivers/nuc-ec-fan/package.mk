# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nuc-ec-fan"
PKG_VERSION="1.0"
PKG_LICENSE="GPL-2.0-only"
PKG_SITE="https://libreelec.tv"
PKG_URL=""
PKG_LONGDESC="nuc-ec-fan exposes the Intel NUC embedded-controller fan tachometer as a hwmon device"
PKG_IS_KERNEL_PKG="yes"
PKG_ARCH="x86_64"

unpack() {
  mkdir -p ${PKG_BUILD}
    cp -a ${PKG_DIR}/src/* ${PKG_BUILD}
}

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  make V=1 \
       -C $(kernel_path) \
       M=${PKG_BUILD} \
       ARCH=${TARGET_KERNEL_ARCH} \
       CROSS_COMPILE=${TARGET_KERNEL_PREFIX} \
       modules
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
    cp *.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
}
