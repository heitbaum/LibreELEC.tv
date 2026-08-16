# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="acpi_call"
PKG_VERSION="6ad1e676dbfb5dcb1ec1f973c10ef5c57ffb4069"
PKG_SHA256="dc9a762941f68de82f62aee438894d2fecf10b3947b24fd649d38aac1edb9b80"
PKG_LICENSE="GPL-3.0-only"
PKG_SITE="https://github.com/nix-community/acpi_call"
PKG_URL="https://github.com/nix-community/acpi_call/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="acpi_call provides /proc/acpi/call to evaluate ACPI methods from userspace"
PKG_IS_KERNEL_PKG="yes"
PKG_ARCH="x86_64"

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
