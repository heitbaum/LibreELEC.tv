################################################################################
#      This file is part of LibreELEC - https://libreelec.tv
#      Copyright (C) 2018-present Team LibreELEC
#
#  LibreELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  LibreELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with LibreELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

PKG_NAME="nfs-utils"
PKG_VERSION="2.3.1"
PKG_SHA256="96d06b5a86b185815760d8f04c34fdface8fa8b9949ff256ac05c3ebc08335a5"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://nfs.sourceforge.net/"
PKG_URL="https://www.kernel.org/pub/linux/utils/nfs-utils/$PKG_VERSION/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain libevent"
PKG_SECTION="service"
PKG_SHORTDESC="Support programs for Network File Systems"
PKG_LONGDESC="NFS-Server ($PKG_VERSION) is a flexible and powerful server-side application for playing music"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="NFS-Server"
PKG_ADDON_TYPE="xbmc.service"

PKG_CONFIGURE_OPTS_TARGET="--disable-gss \
                           --disable-nfsv41 \
                           --with-systemd \
                           --without-tcp-wrappers \
                           --disable-uuid"

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
