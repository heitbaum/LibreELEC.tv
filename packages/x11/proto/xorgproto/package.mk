# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="xorgproto"
PKG_VERSION="2021.4"
PKG_SHA256="0f5157030162844b398e7ce69b8bb967c2edb8064b0a9c9bb5517eb621459fbf"
PKG_LICENSE="OSS"
PKG_SITE="http://www.X.org"
PKG_URL="https://xorg.freedesktop.org/archive/individual/proto/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain util-macros"
PKG_LONGDESC="combined X.Org X11 Protocol headers"
PKG_TOOLCHAIN="meson"

PKG_MESON_OPTS_TARGET="-Dlegacy=false"
