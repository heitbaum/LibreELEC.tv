# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="googletest"
PKG_VERSION="1.15.2"
PKG_SHA256="7b42b4d6ed48810c5362c265a17faebe90dc2373c885e5216439d37927f02926"
PKG_LICENSE="BSD-3-Clause"
PKG_SITE="https://github.com/google/googletest"
PKG_URL="https://github.com/google/googletest/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host cmake:host"
PKG_LONGDESC="Google Testing and Mocking Framework"
PKG_TOOLCHAIN="cmake-make"
