# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="wayland-protocols"
PKG_VERSION="1.21"
PKG_SHA256="b99945842d8be18817c26ee77dafa157883af89268e15f4a5a1a1ff3ffa4cde5"
PKG_LICENSE="OSS"
PKG_SITE="https://wayland.freedesktop.org/"
PKG_URL="https://wayland.freedesktop.org/releases/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Specifications of extended Wayland protocols"
#to be removed went version updated to allow meson build without wayland-scanner
PKG_TOOLCHAIN="configure"

post_makeinstall_target() {
  rm -rf ${INSTALL}
}
