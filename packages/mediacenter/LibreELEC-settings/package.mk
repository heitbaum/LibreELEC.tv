# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="LibreELEC-settings"
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
PKG_VERSION="db288855d6a971ef29567ebc795301907e145797"
PKG_SHA256="0307258005a7b4bb3ee946e701dd4cdd6817fd45d94a92a49129ce369be5f7cb"
=======
PKG_VERSION="1efa8b5706367941c3a1ea1855e38da4fd592438"
PKG_SHA256="b40f28e688abce0468a715b110623b5c883c5ff182153234a4d05f9c66cc0fa9"
>>>>>>> first commit
=======
PKG_VERSION="2927e633c278454066d99ac12a5b8f69c8246178"
PKG_SHA256="87de2d653e9cb5942c9babfe91bf4548dcc931f924a0ff057846a4ec1d9d37b7"
>>>>>>> update packages
=======
PKG_VERSION="db288855d6a971ef29567ebc795301907e145797"
PKG_SHA256="0307258005a7b4bb3ee946e701dd4cdd6817fd45d94a92a49129ce369be5f7cb"
>>>>>>> another commit
PKG_LICENSE="GPL"
PKG_SITE="https://libreelec.tv"
PKG_URL="https://github.com/LibreELEC/service.libreelec.settings/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3 connman pygobject dbus-python dbussy"
PKG_LONGDESC="LibreELEC-settings: is a settings dialog for LibreELEC"

PKG_MAKE_OPTS_TARGET="DISTRONAME=$DISTRONAME ROOT_PASSWORD=$ROOT_PASSWORD"

if [ "$DISPLAYSERVER" = "x11" ]; then
  PKG_DEPENDS_TARGET+=" setxkbmap"
else
  PKG_DEPENDS_TARGET+=" bkeymaps"
fi

post_makeinstall_target() {
  mkdir -p $INSTALL/usr/lib/libreelec
    cp $PKG_DIR/scripts/* $INSTALL/usr/lib/libreelec
    sed -e "s/@DISTRONAME@/$DISTRONAME/g" \
      -i $INSTALL/usr/lib/libreelec/backup-restore

  ADDON_INSTALL_DIR=$INSTALL/usr/share/kodi/addons/service.libreelec.settings

  python_compile $ADDON_INSTALL_DIR/resources/lib/

  python_compile $ADDON_INSTALL_DIR/defaults.py

  python_compile $ADDON_INSTALL_DIR/oe.py
}

post_install() {
  enable_service backup-restore.service
  enable_service factory-reset.service
}
