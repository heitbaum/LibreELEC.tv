# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="xorgproto"
PKG_VERSION="2021.3"
PKG_SHA256="4c732b14fc7c7db64306374d9e8386d6172edbb93f587614df1938b9d9b9d737"
PKG_LICENSE="OSS"
PKG_SITE="http://www.X.org"
PKG_URL="https://xorg.freedesktop.org/archive/individual/proto/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain util-macros"
PKG_LONGDESC="combined X.Org X11 Protocol headers"
PKG_TOOLCHAIN="meson"

PKG_MESON_OPTS_TARGET="-Dlegacy=false"
