# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="screensaver.greynetic"
PKG_VERSION="2955c4105ea1223e9901dbc804812bdb3c0412a7"
PKG_SHA256="0974661ce4725e685222cce04b9f43d24b4161f8af9400b6e739549368a0e1eb"
PKG_REV="2"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/xbmc/screensaver.greynetic"
PKG_URL="https://github.com/xbmc/screensaver.greynetic/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain kodi-platform glm"
PKG_SECTION=""
PKG_SHORTDESC="screensaver.greynetic"
PKG_LONGDESC="screensaver.greynetic"

PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="xbmc.ui.screensaver"

if [ "${OPENGL}" = "no" ]; then
  exit 0
fi
