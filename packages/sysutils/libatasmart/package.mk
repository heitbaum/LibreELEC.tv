# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libatasmart"
PKG_VERSION="0.19"
PKG_SHA256="61f0ea345f63d28ab2ff0dc352c22271661b66bf09642db3a4049ac9dbdb0f8d"
PKG_LICENSE="LGPLv2.1"
PKG_SITE="http://0pointer.de/blog/projects/being-smart.html"
PKG_URL="http://0pointer.de/public/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain systemd"
PKG_LONGDESC="ATA S.M.A.R.T. Reading and Parsing Library"

pre_make_target() {
  # building host tools seems to be broken in 0.19, prebuild these
  make CFLAGS="${HOST_CFLAGS}" LDFLAGS="${HOST_LDFLAGS}" CC="${HOST_CC}" -C strpool
}
