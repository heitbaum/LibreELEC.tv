# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="rar2fs"
PKG_VERSION="1.29.4"
PKG_SHA256="ce7e1314bad4db92670edde2668785b8e4d7b8b886df5280101b2f61be0a7f93"
PKG_LICENSE="GPL3"
PKG_SITE="https://github.com/hasse69/rar2fs"
PKG_URL="https://github.com/hasse69/rar2fs/releases/download/v${PKG_VERSION}/rar2fs-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain fuse unrar"
PKG_LONGDESC="FUSE file system for reading RAR archives"
PKG_BUILD_FLAGS="-sysroot"

pre_configure_target() {
  PKG_CONFIGURE_OPTS_TARGET="--with-unrar=${PKG_BUILD}/unrar \
                             --with-unrar-lib=${PKG_BUILD}/unrar \
                             --disable-static-unrar"
  cp -a $(get_install_dir unrar)/usr/include/unrar ${PKG_BUILD}/
  cp -p $(get_install_dir unrar)/usr/lib/libunrar.a ${PKG_BUILD}/unrar/
}
