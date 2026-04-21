# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="git"
PKG_VERSION="2.54.0"
PKG_SHA256="f689162364c10de79ef89aa8dbf48731eb057e34edbbd20aca510ce0154681a3"
PKG_LICENSE="GPL-2.0-only"
PKG_SITE="https://git-scm.com"
PKG_URL="https://www.kernel.org/pub/software/scm/git/git-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="fast, scalable, distributed revision control system"
PKG_BUILD_FLAGS="-sysroot"

PKG_MESON_OPTS_TARGET="-Dperl=disabled \
                       -Drust=disabled"
