# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="snapcast"
PKG_VERSION="0.23.0"
PKG_SHA256="70efdeea60021f493f77ba1f3d00784911463cad11c6df214ecb19d74899b611"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/badaix/snapcast"
PKG_URL="https://github.com/badaix/snapcast/archive/v$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain aixlog alsa-lib asio avahi flac libvorbis popl boost opus"
PKG_LONGDESC="Synchronous multi-room audio player."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  cd ..
  rm -rf .$TARGET_NAME
  CXXFLAGS="$CXXFLAGS -pthread \
                      -I$(get_build_dir aixlog)/include \
                      -I$(get_build_dir asio)/asio/include \
                      -I$(get_build_dir popl)/include"
}

makeinstall_target() {
  :
}
