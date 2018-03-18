################################################################################
#      This file is part of LibreELEC - https://libreelec.tv
#      Copyright (C) 2017-present Team LibreELEC
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

PKG_NAME="nfs-ganesha"
PKG_VERSION="9786797"
PKG_SHA256="16778a8147095349192dcbedf34df711f6d0323cb35061126ddb7b143b6baea7"
PKG_REV="100"
PKG_ARCH="any"
PKG_LICENSE="LGPL"
PKG_SITE="https://github.com/nfs-ganesha/nfs-ganesha/"
PKG_URL="$DISTRO_SRC/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="service"
PKG_SHORTDESC="NFS-Ganesha is a NFS server in User Space"
PKG_LONGDESC="NFS-Ganesha is a NFS server in User Space"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="NFS Server"
PKG_ADDON_TYPE="xbmc.service"

PKG_CMAKE_OPTS_TARGET="-DUSE_GUI_ADMIN_TOOLS=OFF \
                       -DUSE_GSS=OFF \
                       -DUSE_NFSIDMAP=OFF \
                       -DUSE_FSAL_CEPH=OFF \
                       -DUSE_FSAL_GLUSTER=OFF \
                       -DUSE_FSAL_XFS=OFF \
                       -DCMAKE_BUILD_TYPE=Release \
                       -DUSE_RADOS_RECOV=OFF"

makeinstall_target() {
  :
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin
  cp -P $PKG_BUILD/.$TARGET_NAME/MainNFSD/ganesha.nfsd $ADDON_BUILD/$PKG_ADDON_ID/bin

  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/lib/ganesha
  cp $PKG_BUILD/.$TARGET_NAME/libntirpc/src/libntirpc.so.1.6 $ADDON_BUILD/$PKG_ADDON_ID/lib
  cp $PKG_BUILD/.$TARGET_NAME/FSAL/FSAL_VFS/vfs/libfsalvfs.so $ADDON_BUILD/$PKG_ADDON_ID/lib/ganesha


  # set only version (revision will be added by buildsystem)
  cp $PKG_DIR/addon.xml $ADDON_BUILD/$PKG_ADDON_ID
  $SED -e "s|@ADDON_VERSION@|$ADDON_VERSION|g" \
       -i $ADDON_BUILD/$PKG_ADDON_ID/addon.xml
}
