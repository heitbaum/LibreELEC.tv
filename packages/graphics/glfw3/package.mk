# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="glfw3"
PKG_VERSION="3.3.2"
PKG_SHA256="aa9a2325c3d2cb3a18b236326b3f866545a46cd48514b00c999fdd9374a7325b"
PKG_ARCH="x86_64"
PKG_LICENSE="BSD"
PKG_SITE="http://glfw.org"
PKG_URL="$SOURCEFORGE_SRC/glfw/glfw-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain mesa glu libXcursor libXinerama libXi"
PKG_LONGDESC="provides a simple API for creating windows, contexts and surfaces, receiving input and events"

if [ "$OPENGL" = "no" ] ; then
  exit 0
fi
