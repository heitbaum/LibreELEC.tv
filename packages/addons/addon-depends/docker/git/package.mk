# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="git"
PKG_VERSION="2.56.0"
PKG_SHA256="26c56c296b38c0695b26fa95f475f1d01704d2d38e73465ca30b0b2f5dc789d3"
PKG_LICENSE="GPL-2.0-only"
PKG_SITE="https://git-scm.com"
PKG_URL="https://www.kernel.org/pub/software/scm/git/git-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="fast, scalable, distributed revision control system"
PKG_BUILD_FLAGS="-sysroot"

PKG_MESON_OPTS_TARGET="-Dperl=disabled \
                       -Drust=disabled"
