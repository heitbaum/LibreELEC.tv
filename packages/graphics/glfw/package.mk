# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="glfw"
PKG_VERSION="3.3.10"
PKG_SHA256="4ff18a3377da465386374d8127e7b7349b685288cb8e17122f7e1179f73769d5"
PKG_ARCH="x86_64"
PKG_LICENSE="BSD"
PKG_SITE="https://glfw.org"
PKG_URL="https://github.com/${PKG_NAME}/${PKG_NAME}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain mesa glu libXcursor libXinerama libXi"
PKG_LONGDESC="provides a simple API for creating windows, contexts and surfaces, receiving input and events"

if [ "${OPENGL}" = "no" ] ; then
  exit 0
fi
