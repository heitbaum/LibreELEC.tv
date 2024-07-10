# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="exiv2"
PKG_VERSION="0.28.9"
PKG_SHA256="700b76b97695b2fab4ef8c79619c68ae57d09e0c130724791cafbd39e0eb4aef"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://exiv2.org"
PKG_URL="https://github.com/Exiv2/exiv2/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain zlib"
PKG_LONGDESC="Exiv2 is a Cross-platform C++ library to manage image metadata."

PKG_MESON_OPTS_TARGET="-Ddefault_library=static \
                       -Dwebready=false \
                       -Dxmp=disabled \
                       -Dcurl=disabled \
                       -Dnls=disabled \
                       -Dtests=false \
                       -DunitTests=disabled \
                       -Dvideo=false \
                       -Dbmff=false \
                       -Dbrotli=disabled \
                       -Dinih=disabled \
                       -Dapp=false"
