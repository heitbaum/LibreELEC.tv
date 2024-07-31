# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="screensaver.stars"
PKG_VERSION="e31111555b41692fd373719a9ba74aba3e7f4790"
PKG_SHA256="84d63373984f83e04bb8990a00a5b57a95ddd595f6a2b5fdf56bbd424cd546c8"
PKG_REV="2"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/xbmc/screensaver.stars"
PKG_URL="https://github.com/xbmc/screensaver.stars/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain kodi-platform"
PKG_SECTION=""
PKG_SHORTDESC="screensaver.stars"
PKG_LONGDESC="screensaver.stars"

PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="xbmc.ui.screensaver"

if [ "${OPENGL}" = "no" ]; then
  exit 0
fi
