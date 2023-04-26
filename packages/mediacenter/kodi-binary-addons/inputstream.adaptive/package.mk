# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="inputstream.adaptive"
PKG_VERSION="4144ae32e7ecae4d0b07c8cf63a73c03c4a3b812"
PKG_SHA256="202a074cc1a1f8d691436feb3b2bb5c191e17510f4c67d1440c21d3422c88e6e"
PKG_REV="2"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/xbmc/inputstream.adaptive"
PKG_URL="https://github.com/xbmc/inputstream.adaptive/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain kodi-platform bento4 expat nss pugixml"
PKG_SECTION=""
PKG_SHORTDESC="inputstream.adaptive"
PKG_LONGDESC="inputstream.adaptive"

PKG_IS_ADDON="yes"

addon() {
  install_binary_addon ${PKG_ADDON_ID}

  mkdir -p ${ADDON_BUILD}/${PKG_ADDON_ID}
  cp -P ${PKG_BUILD}/.${TARGET_NAME}/wvdecrypter/libssd_wv.so ${ADDON_BUILD}/${PKG_ADDON_ID}
}
