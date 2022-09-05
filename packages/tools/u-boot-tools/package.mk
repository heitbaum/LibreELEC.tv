# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="u-boot-tools"
PKG_VERSION="2022.10-rc3"
PKG_SHA256="23bdeee41dffc068c04dc756ed607da644b4586363bbed68c40e8c47f59641f0"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_URL="https://ftp.denx.de/pub/u-boot/u-boot-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_HOST="ccache:host bison:host flex:host openssl:host pkg-config:host"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems."

make_host() {
  make qemu-x86_64_defconfig HOSTCC="${HOST_CC}" HOSTCFLAGS="-I${TOOLCHAIN}/include" HOSTLDFLAGS="${HOST_LDFLAGS}"
  make tools-only HOSTCC="${HOST_CC}" HOSTCFLAGS="-I${TOOLCHAIN}/include" HOSTLDFLAGS="${HOST_LDFLAGS}"
}

make_target() {
  : # host-only package
}

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/bin
    cp tools/mkimage ${TOOLCHAIN}/bin
}
