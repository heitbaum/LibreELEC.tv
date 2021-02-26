# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="liberation-fonts-ttf"
PKG_VERSION="2.1.4"
PKG_SHA256="26f85412dd0aa9d061504a1cc8aaf0aa12a70710e8d47d8b65a1251757c1a5ef"
PKG_LICENSE="OFL1_1"
PKG_SITE="https://github.com/liberationfonts/liberation-fonts"
PKG_URL="https://github.com/liberationfonts/liberation-fonts/files/6418984/${PKG_NAME}-${PKG_VERSION}.tar.gz"
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
