# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="efivar"
PKG_VERSION="38"
PKG_SHA256="e3bbde37238bd47af1fcf270dc0ef1f4be030d86364c917b93669222ec52bbea"
PKG_ARCH="x86_64"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/rhboot/efivar"
PKG_URL="https://github.com/rhboot/efivar/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain efivar:host"
PKG_LONGDESC="Tools and library to manipulate EFI variables."
PKG_BUILD_FLAGS="-gold +pic"

pre_make_host() {
  export TOPDIR=${PKG_BUILD}
}

make_host() {
  make -C src/ include/efivar/efivar-guids.h
}

pre_make_target() {
  sed -e 's/-Werror//' -i src/include/gcc.specs
  export TOPDIR=${PKG_BUILD}
}

make_target() {
  LDFLAGS+=" -Wl,--no-warn-rwx-segments"
  make CROSS_COMPILE=${TARGET_NAME}- -C src/ libefivar.a libefiboot.a efivar.h efivar
}

makeinstall_host() {
  : # noop
}

makeinstall_target() {
  mkdir -p ${SYSROOT_PREFIX}/usr/lib
    cp -P src/libefivar.a src/libefiboot.a ${SYSROOT_PREFIX}/usr/lib/

  mkdir -p ${SYSROOT_PREFIX}/usr/include/efivar
    cp -P src/include/efivar/*.h ${SYSROOT_PREFIX}/usr/include/efivar
}
