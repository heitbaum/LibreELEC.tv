# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="exiv2"
PKG_VERSION="0.28.7"
PKG_SHA256="5e292b02614dbc0cee40fe1116db2f42f63ef6b2ba430c77b614e17b8d61a638"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://exiv2.org"
PKG_URL="https://github.com/Exiv2/exiv2/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
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
