# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="googletest"
PKG_VERSION="1.15.0"
PKG_SHA256="7315acb6bf10e99f332c8a43f00d5fbb1ee6ca48c52f6b936991b216c586aaad"
PKG_LICENSE="BSD-3-Clause"
PKG_SITE="https://github.com/google/googletest"
PKG_URL="https://github.com/google/googletest/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host cmake:host"
PKG_LONGDESC="Google Testing and Mocking Framework"
PKG_TOOLCHAIN="cmake-make"
