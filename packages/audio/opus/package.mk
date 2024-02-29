# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="opus"
PKG_VERSION="1.5.2"
PKG_SHA256="65c1d2f78b9f2fb20082c38cbe47c951ad5839345876e46941612ee87f9a7ce1"
PKG_LICENSE="BSD"
PKG_SITE="http://www.opus-codec.org"
PKG_URL="https://github.com/xiph/opus/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Codec designed for interactive speech and audio transmission over the Internet."
PKG_BUILD_FLAGS="+pic"

#post_patch() {
#  # if using a git hash as a package version - set package_version
#  echo "PACKAGE_VERSION=\"1.4-git-${PKG_VERSION:0:7}\"" > ${PKG_BUILD}/package_version
#  (cd ${PKG_BUILD}; ./autogen.sh)
#}

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
