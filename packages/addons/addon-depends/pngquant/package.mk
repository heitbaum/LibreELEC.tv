# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="pngquant"
PKG_VERSION="2.15.0"
PKG_SHA256="c5051b9eb3de5acd1ee3b5b4cc87036b25289277fcef8f293a35f84da71e5a04"
PKG_LICENSE="GPLv3"
PKG_SITE="https://pngquant.org"
PKG_URL="https://pngquant.org/pngquant-${PKG_VERSION}-src.tar.gz"
PKG_DEPENDS_HOST="toolchain:host libpng:host zlib:host"
PKG_LONGDESC="A lossy PNG compressor."

configure_host() {
  :
}

make_host() {
  cd ${PKG_BUILD}
  BIN=${PKG_BUILD}/pngquant make

  ${STRIP} ${PKG_BUILD}/pngquant
}

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/bin
    cp ${PKG_BUILD}/pngquant ${TOOLCHAIN}/bin
}
