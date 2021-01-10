# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libdvdnav"
# From https://github.com/howie-f/libdvdnav/releases/tag/6.1.0-Matrix-Beta-2
PKG_VERSION="724039332ab2d1dab342a279afd74bd436b4a78f" # 2020-12-12
PKG_SHA256="48469044e38740706d91b738e6233b584a65dfb72b3e7a6c76903c07332046c2"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/xbmc/libdvdnav"
PKG_URL="https://github.com/xbmc/libdvdnav/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libdvdread"
PKG_LONGDESC="libdvdnav is a library that allows easy use of sophisticated DVD navigation features such as DVD menus, multiangle playback and even interactive DVD games."
PKG_TOOLCHAIN="manual"
