# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="patchelf"
PKG_VERSION="0.17.2"
PKG_SHA256="bae2ea376072e422c196218dd9bdef0548ccc08da4de9f36b4672df84ea2d8e2"
PKG_LICENSE="BSD"
PKG_SITE="https://github.com/NixOS/patchelf"
PKG_URL="https://github.com/NixOS/patchelf/releases/download/${PKG_VERSION}/patchelf-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_HOST="toolchain:host"
PKG_LONGDESC="A small utility to modify the dynamic linker and RPATH of ELF executables"
PKG_TOOLCHAIN="autotools"
