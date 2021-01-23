# SPDX-License-Identifier: GPL-2.0-or-only
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="open-isns"
PKG_VERSION="0.103"
PKG_SHA256="47499f3ce87a832840884dcf3eedbec8c039f472fe921a5378e3b206a3fc1a32"
PKG_LICENSE="LGPL2.1"
PKG_SITE="https://github.com/open-iscsi/open-isns"
PKG_URL="https://github.com/open-iscsi/open-isns/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain util-linux"
PKG_LONGDESC="iSNS server and client for Linux"

post_makeinstall_target() {
  safe_remove ${INSTALL}/etc
  safe_remove ${INSTALL}/usr/sbin
}
