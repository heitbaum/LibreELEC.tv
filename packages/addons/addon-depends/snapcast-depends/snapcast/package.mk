# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="snapcast"
PKG_VERSION="0.29.0"
PKG_SHA256="ecfb2c96a4920adc4121b1180b37bb86566c359914c14831c0abea4e65d23f92"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/badaix/snapcast"
PKG_URL="https://github.com/badaix/snapcast/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain aixlog alsa-lib asio avahi flac libvorbis popl pulseaudio boost opus"
PKG_LONGDESC="Synchronous multi-room audio player."
PKG_BUILD_FLAGS="-sysroot"

pre_configure_target() {
  CXXFLAGS="${CXXFLAGS} -pthread \
                      -I$(get_install_dir aixlog)/usr/include \
                      -I$(get_install_dir asio)/usr/include \
                      -I$(get_install_dir popl)/usr/include"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -p ../bin/{snapclient,snapserver} ${INSTALL}/usr/bin
}
