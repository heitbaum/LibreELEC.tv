# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="open-isns"
PKG_VERSION="0.101"
PKG_SHA256="f672ec86b6c9e984843a7a28d76f07e26393499c486f86034b8b18caa8deb556"
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
