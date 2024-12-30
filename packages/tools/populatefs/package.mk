# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="populatefs"
PKG_VERSION="8d7fd68786d20eb40337da5dbae3992fbda78317"
PKG_SHA256="c5e46e174a25ebf64b158a80b2c1579e7fbe5c7173a0a4cd767a2a6ff4356736"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/kfix/populatefs"
PKG_URL="https://github.com/kfix/${PKG_NAME}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="e2fsprogs:host"
PKG_LONGDESC="populatefs: Tool for replacing genext2fs when creating ext4 images"
PKG_BUILD_FLAGS="+pic:host"

make_host() {
  make EXTRA_LIBS="-lcom_err -lpthread"
}

makeinstall_host() {
  ${STRIP} src/populatefs

  mkdir -p ${TOOLCHAIN}/sbin
  cp src/populatefs ${TOOLCHAIN}/sbin
}
