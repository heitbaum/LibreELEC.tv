# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="glfw"
PKG_VERSION="3.3.6"
PKG_SHA256="ed07b90e334dcd39903e6288d90fa1ae0cf2d2119fec516cf743a0a404527c02"
PKG_ARCH="x86_64"
PKG_LICENSE="BSD"
PKG_SITE="https://glfw.org"
PKG_URL="https://github.com/${PKG_NAME}/${PKG_NAME}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain mesa glu libXcursor libXinerama libXi"
PKG_LONGDESC="provides a simple API for creating windows, contexts and surfaces, receiving input and events"

if [ "${OPENGL}" = "no" ] ; then
  exit 0
fi
