# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Frank Hartung (supervisedthinking (@) gmail.com)

PKG_NAME="makemkv-bin"
PKG_VERSION="1.16.1"
PKG_SHA256="941f88acfb3790ecc008b2675e8ad3d0353f0163778cc1cb9507aa87c3427db6"
PKG_ARCH="aarch64 arm x86_64"
PKG_LICENSE="OSS"
PKG_SITE="http://www.makemkv.com/"
PKG_URL="http://www.makemkv.com/download/makemkv-bin-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="MakeMKV binaries & EULA"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  :
}
