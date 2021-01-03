# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libretro-common"
PKG_VERSION="28d79775c3463adabe156402a585251b0cfeaa13"
PKG_SHA256="0c2011350d617fa6a7137a577b3aab65f1b3ec72c3678f4a6d2f0236b2a25a7a"
PKG_LICENSE="Permissively licensed"
PKG_SITE="https://github.com/libretro/libretro-common"
PKG_URL="https://github.com/libretro/libretro-common/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain kodi-platform"
PKG_LONGDESC="game.libretro.common: git submodule used by libretro"
PKG_TOOLCHAIN="manual"

make_target() {
  :
}

makeinstall_target() {
  :
}
