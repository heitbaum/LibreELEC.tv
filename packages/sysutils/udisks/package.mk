# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="udisks"
PKG_VERSION="2.10.1"
PKG_SHA256="b75734ccf602540dedb4068bec206adcb508a4c003725e117ae8f994d92d8ece"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://storaged.org"
PKG_URL="https://github.com/storaged-project/udisks/releases/download/${PKG_NAME}-${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain libatasmart libblockdev libgudev systemd"
PKG_LONGDESC="UDisks provides tools and libraries to access and manipulate disks, storage devices and technologies"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--disable-acl \
                           --enable-daemon \
                           --disable-btrfs \
                           --disable-crypto \
                           --enable-fhs-media \
                           --disable-iscsi \
                           --disable-libsystemd-login \
                           --disable-lsm \
                           --disable-lvm2 \
                           --disable-man \
                           --disable-mdraid \
                           --disable-polkit \
                           --disable-modules \
                           --disable-available-modules"

post_makeinstall_target() {
  :
  mv ${INSTALL}/usr/lib/udisks2/udisksd ${INSTALL}/usr/lib/udisks2/udisksd.x
  rm -rf ${INSTALL}/usr/lib/udev/rules.d/80-udisks2.rules
  rm -rf ${INSTALL}/usr/lib/systemd/system/udisks2.service
  rm -rf ${INSTALL}/usr/lib/tmpfiles.d/udisks2.conf
}
