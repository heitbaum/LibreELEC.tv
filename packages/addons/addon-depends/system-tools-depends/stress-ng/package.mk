# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="stress-ng"
PKG_VERSION="0.17.08"
PKG_SHA256="e4982d2a1c57139dad1741d6248b00a30935f746c1f665ec5b9d53c010c8dc08"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/ColinIanKing/stress-ng"
PKG_URL="https://github.com/ColinIanKing/stress-ng/archive/refs/tags/V${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain attr keyutils libaio libcap zlib"
PKG_LONGDESC="stress-ng will stress test a computer system in various selectable ways"
PKG_BUILD_FLAGS="-sysroot"
