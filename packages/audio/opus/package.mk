# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="opus"
PKG_VERSION="a8e4ebb550dbdbb6149ad02d390c34442c8db951"
PKG_SHA256="4da441987f0885883b5605b5ab6ac9f92a7f381e1a48d8d87135c353ef6047f0"
PKG_LICENSE="BSD"
PKG_SITE="http://www.opus-codec.org"
PKG_URL="https://github.com/xiph/opus/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_URL="https://github.com/xiph/opus/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Codec designed for interactive speech and audio transmission over the Internet."
PKG_BUILD_FLAGS="+pic"

post_unpack() {
  # if using a git hash as a package version - set package_version
  echo "PACKAGE_VERSION=\"1.4-git-${PKG_VERSION:0:7}\"" > ${PKG_BUILD}/package_version
  (cd ${PKG_BUILD}; ./autogen.sh)
}

if [ "${TARGET_ARCH}" = "arm" ]; then
  PKG_FIXED_POINT="-Dfixed-point=true"
else
  PKG_FIXED_POINT="-Dfixed-point=false"
fi

PKG_MESON_OPTS_TARGET="-Ddefault_library=static \
                       -Ddocs=disabled \
                       -Dextra-programs=disabled \
                       -Dtests=disabled \
                       ${PKG_FIXED_POINT}"
