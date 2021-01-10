# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libdvdread"
# From https://github.com/howie-f/libdvdread/releases/tag/6.1.1-Matrix-Beta-2
PKG_VERSION="ec3b447bb9f2ef4bb64b8e9ebd71ea377a1f4783" # 2020-12-12
PKG_SHA256="7bc6206a771b5cd4977dcf009793b8f6f4b9ac16e5368c5175f7584e304e53bf"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/xbmc/libdvdread"
PKG_URL="https://github.com/xbmc/libdvdread/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libdvdread is a library which provides a simple foundation for reading DVDs."
PKG_TOOLCHAIN="manual"

if [ "${KODI_DVDCSS_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" libdvdcss"
fi
