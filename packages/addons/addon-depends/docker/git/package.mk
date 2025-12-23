# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="git"
PKG_VERSION="2.55.0"
PKG_SHA256="457fdb04dc8728e007d4688695e6912e6f680727920f2a40bf11eacc17505357"
PKG_LICENSE="GPL-2.0-only"
PKG_SITE="https://git-scm.com"
PKG_URL="https://www.kernel.org/pub/software/scm/git/git-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="fast, scalable, distributed revision control system"
PKG_BUILD_FLAGS="-sysroot"

PKG_MESON_OPTS_TARGET="-Dperl=disabled \
                       -Drust=disabled"
