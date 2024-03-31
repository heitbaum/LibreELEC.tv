# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="pvr.iptvsimple"
PKG_VERSION="21.8.4-Omega"
PKG_SHA256="287d9fe5ca348f70b7fae96be7de0e0f092e9a00a3e8043c67ad24bd77a9a82d"
PKG_REV="2"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/kodi-pvr/pvr.iptvsimple"
PKG_URL="https://github.com/kodi-pvr/pvr.iptvsimple/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain kodi-platform pugixml zlib xz"
PKG_SECTION=""
PKG_SHORTDESC="pvr.iptvsimple"
PKG_LONGDESC="pvr.iptvsimple"

PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="xbmc.pvrclient"

pre_configure_target() {
  ls -la  ../Findlzma.cmake
  sed -i -e "s#^find_path(LZMA_INCLUDE_DIRS lzma.h#find_path(LZMA_INCLUDE_DIRS lzma.h PATHS $(get_install_dir xz)/usr/include NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH#" \
         -e "s#^find_library(LZMA_LIBRARIES NAMES lzma liblzma#find_library(LZMA_LIBRARIES NAMES lzma liblzma PATHS $(get_install_dir xz)/usr/lib NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH#" ../Findlzma.cmake
}
