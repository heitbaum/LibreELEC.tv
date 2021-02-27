# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="glfw"
PKG_VERSION="3.3.3"
PKG_SHA256="aa9922b55a464d5bab58fcbe5a619f517d54e3dc122361c116de573670006a7a"
PKG_ARCH="x86_64"
PKG_LICENSE="BSD"
PKG_SITE="http://glfw.org"
#PKG_URL="$SOURCEFORGE_SRC/glfw/glfw-$PKG_VERSION.tar.gz"
PKG_URL="https://github.com/${PKG_NAME}/${PKG_NAME}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain mesa glu libXcursor libXinerama libXi"
PKG_LONGDESC="provides a simple API for creating windows, contexts and surfaces, receiving input and events"

if [ "$OPENGL" = "no" ] ; then
  exit 0
fi
