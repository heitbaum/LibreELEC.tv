# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libblockdev"
PKG_VERSION="3.5.0"
PKG_SHA256="bccd30e6b5d11504de60d9889ff6a2a25b07a4ec8f04070f2387e168301b3e3a"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://storaged.org"
PKG_URL="https://github.com/storaged-project/libblockdev/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain e2fsprogs libatasmart libnvme util-linux"
PKG_LONGDESC="A library for manipulating block devices"

PKG_CONFIGURE_OPTS_TARGET="--without-btrfs \
                           --without-crypto \
                           --without-dm \
                           --without-escrow \
                           --with-fs \
                           --without-gtk-doc \
                           --without-lvm \
                           --without-lvm-dbus \
                           --without-mdraid \
                           --without-mpath \
                           --without-nvdimm \
                           --with-nvme \
                           --with-part \
                           --without-python3 \
                           --with-smart \
                           --without-smartmontools \
                           --with-swap \
                           --disable-tests \
                           --without-tools"

pre_configure_target() {
  export PKG_CONFIG="${PKG_CONFIG} --static"
}
