# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="vsxu"
PKG_VERSION="0.6.3"
PKG_SHA256="f4dd680de9183ebba4f7d75172fc498d656d21f9d15a16f1afdecc3f95accc65"
PKG_ARCH="x86_64"
PKG_LICENSE="GPL"
PKG_SITE="http://www.vsxu.com"
# repackaged from https://github.com/vovoid/vsxu/archive/$PKG_VERSION.tar.gz
#PKG_URL="$DISTRO_SRC/$PKG_NAME-$PKG_VERSION.tar.xz"
#PKG_URL="https://github.com/vovoid/vsxu/archive/v$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain $OPENGL libX11 glew glfw zlib libpng libjpeg-turbo freetype pulseaudio alsa-lib SDL2"
PKG_LONGDESC="an OpenGL-based programming environment to visualize music and create graphic effects"
PKG_DEPENDS_CONFIG="glfw"

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=0 \
                       -DVSXU_STATIC=1 \
                       -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
                       -DCMAKE_CXX_FLAGS=-I$SYSROOT_PREFIX/usr/include/freetype2"

pre_configure_target(){
  export LDFLAGS="$LDFLAGS -lX11"
}

post_makeinstall_target() {
  mkdir -p $SYSROOT_PREFIX/usr/lib/vsxu
  cp -PR $INSTALL/usr/lib/* $SYSROOT_PREFIX/usr/lib

  mkdir -p $SYSROOT_PREFIX/usr/include/
  cp -RP $INSTALL/usr/include/* $SYSROOT_PREFIX/usr/include

  mkdir -p $SYSROOT_PREFIX/usr/share/
    cp -RP $INSTALL/usr/share/vsxu $SYSROOT_PREFIX/usr/share
}

build_tar() {
  # https://github.com/vovoid/vsxu/blob/master/README.md
  git clone https://github.com/vovoid/vsxu.git
  cd vsxu
  git submodule update --init
  rm -rf ../vsxu/.git
  rm ../vsxu/lib/engine_graphics/thirdparty/lodepng/.git
  rm ../vsxu/lib/engine_graphics/thirdparty/ftgl/.git
  rm ../vsxu/lib/engine_graphics/thirdparty/freetype2/.git
  rm ../vsxu/lib/compression/thirdparty/lzma-sdk/.git
  rm ../vsxu/lib/compression/thirdparty/lzham-sdk/.git
  rm ../vsxu/dependencies/.git
  rm ../vsxu/plugins/src/mesh.importers/cal3d/.git
  cd ..
  mv vsxu vsxu-0.6.3
  tar -cJf vsxu-0.6.3.tar.xz vsxu-0.6.3
  cat ../vsxu-0.6.3.tar.xz | sha256sum > sources/vsxu/vsxu-0.6.3.tar.xz.sha256
}
