# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="nfs-utils"
PKG_VERSION="2.6.2"
PKG_SHA256="5200873e81c4d610e2462fc262fe18135f2dbe78b7979f95accd159ae64d5011"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://nfs.sourceforge.net/"
PKG_URL="https://www.kernel.org/pub/linux/utils/nfs-utils/$PKG_VERSION/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain libevent"
PKG_SECTION="service"
PKG_LONGDESC="NFS-Server ($PKG_VERSION) is a flexible and powerful server-side application for playing music"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="NFS-Server"
PKG_ADDON_TYPE="xbmc.service"

PKG_CONFIGURE_OPTS_TARGET="--disable-gss \
                           --disable-ipv6 \
                           --disable-nfsv41 \
                           --disable-uuid \
                           --with-systemd \
                           --without-tcp-wrappers"

pre_configure_target() {
  cd ..
  rm -rf .$TARGET_NAME
}

makeinstall_target() {
  :
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $PKG_BUILD/utils/mount/mount.nfs $ADDON_BUILD/$PKG_ADDON_ID/bin/mount.nfs4
}
