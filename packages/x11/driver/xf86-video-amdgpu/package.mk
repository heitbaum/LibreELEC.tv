# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="xf86-video-amdgpu"
PKG_VERSION="25.0.0"
PKG_SHA256="7653cead024a6820ed1139958503278d78b4b3f80befcacf54ce87a5199b0ce2"
PKG_ARCH="x86_64"
PKG_LICENSE="OSS"
PKG_SITE="https://www.x.org/wiki/RadeonFeature/"
PKG_URL="https://www.x.org/archive/individual/driver/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain libdrm xorg-server"
PKG_LONGDESC="Xorg driver for AMD Radeon GPUs using the amdgpu kernel driver."

PKG_MESON_OPTS_TARGET="-Dudev=enabled \
                       -Dglamor=enabled \
                       -Dmoduledir=${XORG_PATH_MODULES}"

post_makeinstall_target() {
  rm -r ${INSTALL}/usr/share
  mkdir -p ${INSTALL}/etc/X11
    cp ${PKG_BUILD}/conf/10-amdgpu.conf ${INSTALL}/etc/X11/xorg-amdgpu.conf
}
