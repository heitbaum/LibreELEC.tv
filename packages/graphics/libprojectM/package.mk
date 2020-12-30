# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libprojectM"
PKG_VERSION="3.1.8"
PKG_SHA256="cb52e7f4e72b1b60e7a2a5e1a7b110b909c42b622a9fb328b4e7b186614f51a0"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/projectM-visualizer/projectm"
PKG_URL="https://github.com/projectM-visualizer/projectm/archive/v$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain freetype glm $OPENGL"
PKG_LONGDESC="A MilkDrop compatible opensource music visualizer."
PKG_TOOLCHAIN="configure"
PKG_BUILD_FLAGS="+pic"

PKG_CONFIGURE_OPTS_TARGET="--disable-shared \
                           --enable-static \
                           --disable-qt \
                           --disable-pulseaudio \
                           --disable-jack \
                           --enable-preset-subdirs"

# workaround due broken release files, remove at next bump
pre_configure_target() {
  ./autogen.sh
}
