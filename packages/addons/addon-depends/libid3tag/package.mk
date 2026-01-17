# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libid3tag"
PKG_VERSION="66e5bfcde56bfb9819cae0ddc6e35462f49dcb85"
PKG_SHA256="cf477a0237d3a606315110056f6ca2f8a60ae9043ef4689c6af2df696f121d50"
PKG_LICENSE="GPL"
PKG_SITE="https://www.underbit.com/products/mad/"
PKG_URL="https://codeberg.org/tenacityteam/libid3tag/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain zlib"
PKG_LONGDESC="A library for id3 tagging."

PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=OFF"
