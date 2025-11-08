# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libatasmart"
PKG_VERSION="9bf6927c02978bb2f08c02c4cf45f3f3b154e41f"
PKG_SHA256="4799ce3a82e131d671da67c5611e4e3d8c9b575d181869441f5b25767c38df64"
PKG_LICENSE="LGPLv2.1"
PKG_SITE="http://0pointer.de/blog/projects/being-smart.html"
PKG_URL="https://github.com/libatasmart/libatasmart/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain systemd libatasmart:host"
PKG_LONGDESC="ATA S.M.A.R.T. Reading and Parsing Library"

PKG_MESON_OPTS_HOST="-Dstrpool_build=true \
                     -Dsrc_build=false"

PKG_MESON_OPTS_TARGET="-Dstrpool_build=false \
                       -Dsrc_build=true"

pre_configure_target() {
  PKG_MESON_OPTS_TARGET+=" -Dstrpool_path=${PKG_BUILD}/.${HOST_NAME}/tools/strpool/strpool"
}
