# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="liberation-fonts-ttf"
PKG_VERSION="2.1.3"
PKG_SHA256="8947bb7c0ad4d0d25b6ae93d40ec5fbe3dbbd4de21b81a62aa0c41a801e36fdd"
PKG_LICENSE="OFL1_1"
PKG_SITE="https://github.com/liberationfonts/liberation-fonts"
PKG_URL="https://github.com/liberationfonts/liberation-fonts/files/6026893/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain util-macros"
PKG_LONGDESC="This packages included the high-quality and open-sourced TrueType vector fonts."
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/fonts/liberation
    cp *.ttf ${INSTALL}/usr/share/fonts/liberation
}

post_install() {
  mkfontdir ${INSTALL}/usr/share/fonts/liberation
  mkfontscale ${INSTALL}/usr/share/fonts/liberation
}
