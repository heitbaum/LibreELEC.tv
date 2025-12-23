# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="git"
PKG_VERSION="2.53.0"
PKG_SHA256="5818bd7d80b061bbbdfec8a433d609dc8818a05991f731ffc4a561e2ca18c653"
PKG_LICENSE="GPL-2.0-only"
PKG_SITE="https://git-scm.com"
PKG_URL="https://www.kernel.org/pub/software/scm/git/git-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="fast, scalable, distributed revision control system"
PKG_BUILD_FLAGS="-sysroot"

PKG_MESON_OPTS_TARGET="-Dperl=disabled \
                       -Drust=disabled"
