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

PKG_NAME="unfsd"
PKG_VERSION="8e324e8"
PKG_SHA256="cc8c14ef0bc4019b74edd6b97f2ed2c4c58cb5bb1a28a4103b3575fc8bee0f9f"
PKG_REV="100"
PKG_ARCH="any"
PKG_LICENSE="BSD"
PKG_SITE="http://unfs3.sourceforge.net/"
PKG_URL="https://github.com/CvH/unfsd/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain flex rpcbind"
PKG_SECTION="service"
PKG_SHORTDESC="unfsd: a NFS server"
PKG_LONGDESC="unfsd ($PKG_VERSION) is a user-space implementation of the NFSv3 server specification."
PKG_TOOLCHAIN="autotools"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="NFS Server"
PKG_ADDON_TYPE="xbmc.service"

PKG_CMAKE_OPTS_TARGET="--sbindir=/usr/bin"

makeinstall_target() {
  :
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin
  cp -P $PKG_BUILD/.$TARGET_NAME/unfsd $ADDON_BUILD/$PKG_ADDON_ID/bin
}
