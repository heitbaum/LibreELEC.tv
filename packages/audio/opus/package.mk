# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="opus"
PKG_VERSION="1.6.1"
PKG_SHA256="6ffcb593207be92584df15b32466ed64bbec99109f007c82205f0194572411a1"
PKG_LICENSE="BSD"
PKG_SITE="http://www.opus-codec.org"
PKG_URL="https://ftp.osuosl.org/pub/xiph/releases/opus/${PKG_NAME}-${PKG_VERSION}.tar.gz"
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
