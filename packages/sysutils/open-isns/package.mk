# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="open-isns"
PKG_VERSION="0.102"
PKG_SHA256="9611344733c0cdf14395f60880950ea4c3c7d6b765565b6493ad3e1afbe216de"
PKG_LICENSE="LGPL2.1"
PKG_SITE="https://github.com/open-iscsi/open-isns"
PKG_URL="https://github.com/open-iscsi/open-isns/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain util-linux"
PKG_LONGDESC="iSNS server and client for Linux"

makeinstall_target() {
  :
}

post_makeinstall_target() {
  export DESTDIR="${SYSROOT_PREFIX}"
  make install_hdrs
  make install_lib
}
