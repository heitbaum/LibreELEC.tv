# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gasket-driver"
PKG_VERSION="5815ee3908a46a415aac616ac7b9aedcb98a504c"
PKG_SHA256="90cb41d10df702ec63b86968e1e7123abef6df1fdef5e7e2138d57618efbffde"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://github.com/google/gasket-driver"
PKG_URL="https://github.com/google/gasket-driver/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="Coral Gasket Driver allows usage of the Coral EdgeTPU on Linux"
PKG_IS_KERNEL_PKG="yes"

post_unpack() {
  mv ${PKG_BUILD}/src/* ${PKG_BUILD}
}

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  make V=1 \
       ARCH=${TARGET_KERNEL_ARCH} \
       KSRC=$(kernel_path) \
       CROSS_COMPILE=${TARGET_KERNEL_PREFIX} \
       CONFIG_POWER_SAVING=n
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
    cp *.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
}
