# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="fatresize"
PKG_VERSION="75cbc388dc7fc6add789812a3f7ddaead2d44379"
PKG_SHA256="c369a5806cafb144147f72165db8c2d482368f380e2aaf735475de7802b038a7"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://github.com/ya-mouse/fatresize"
PKG_URL="https://github.com/ya-mouse/fatresize/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain parted"
PKG_LONGDESC="fatresize resizes FAT16 and FAT32 filesystems in place using libparted."
PKG_TOOLCHAIN="autotools"

# parted is built static, so the private dependencies of libparted have to be
# pulled in explicitly - pkg-config only reports them for a static link.
pre_configure_target() {
  export PARTED_CFLAGS="-I${SYSROOT_PREFIX}/usr/include"
  export PARTED_LIBS="$(${PKG_CONFIG} --static --libs libparted) -lparted-fs-resize"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/sbin
    cp fatresize ${INSTALL}/usr/sbin
}
