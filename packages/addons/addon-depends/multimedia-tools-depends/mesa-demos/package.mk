# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mesa-demos"
PKG_VERSION="8.5.0"
PKG_SHA256="cea2df0a80f09a30f635c4eb1a672bf90c5ddee0b8e77f4d70041668ef71aac1"
PKG_ARCH="x86_64"
PKG_LICENSE="OSS"
PKG_SITE="https://www.mesa3d.org/"
PKG_URL="https://archive.mesa3d.org/demos/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain libX11 mesa glu glew"
PKG_LONGDESC="Mesa 3D demos - installed are the well known glxinfo and glxgears."
PKG_BUILD_FLAGS="-sysroot"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp -P src/xdemos/glxdemo ${INSTALL}/usr/bin
    cp -P src/xdemos/glxgears ${INSTALL}/usr/bin
    cp -P src/xdemos/glxinfo ${INSTALL}/usr/bin
}
