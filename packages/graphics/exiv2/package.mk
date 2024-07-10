# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="exiv2"
PKG_VERSION="0.28.3"
PKG_SHA256="1315e17d454bf4da3cc0edb857b1d2c143670f3485b537d0f946d9ed31d87b70"
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
                       -DEXIV2_BUILD_SAMPLES=disabled \
                       -DunitTests=disabled \
                       -Dvideo=false \
                       -Dbmff=false \
                       -Dbrotli=disabled \
                       -Dinih=disabled \
                       -Dfilesystem_access=OFF \
                       -DEXIV2_BUILD_EXIV2_COMMAND=OFF"
