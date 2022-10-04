# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="kmsxx"
PKG_VERSION="0f3534d3be5750ff9cb03cb997a8efc91de07347"
PKG_SHA256="4ad5b84d55ecf40b7ca2e4369afec4d4ccf00973fb8473a74e31d5e87b9278b1"
PKG_LICENSE="MPL-2.0"
PKG_SITE="https://github.com/tomba/kmsxx"
PKG_URL="https://github.com/tomba/kmsxx/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libdrm libfmt"
PKG_LONGDESC="Library and utilities for kernel mode setting"
PKG_BUILD_FLAGS="-sysroot"

PKG_MESON_OPTS_TARGET="-Ddefault_library=static \
                       -Dkmscube=false \
                       -Domap=disabled \
                       -Dpykms=disabled"

