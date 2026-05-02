# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libretro-uae4arm"
PKG_VERSION="dafd48fad7510ebc2f90ebdee8331bbdcf65fd49"
PKG_SHA256="0ae82a0e126e2bc5fb9571b2267a300ec9b6c61ac93564c9ab351293080e893e"
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPL-2.0-only"
PKG_SITE="https://github.com/libretro/uae4arm-libretro"
PKG_URL="https://github.com/libretro/uae4arm-libretro/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain flac mpg123 zlib"
PKG_LONGDESC="Port of uae4arm for libretro (rpi/android)"
PKG_TOOLCHAIN="make"

PKG_LIBNAME="uae4arm_libretro.so"
PKG_LIBPATH="${PKG_LIBNAME}"
PKG_LIBVAR="UAE4ARM_LIB"

PKG_MAKE_OPTS_TARGET="-f Makefile.libretro"

if [ "${ARCH}" = "aarch64" ]; then
  PKG_MAKE_OPTS_TARGET+=" platform=unix-aarch64"
elif target_has_feature neon; then
  PKG_MAKE_OPTS_TARGET+=" platform=unix-neon"
else
  PKG_MAKE_OPTS_TARGET+=" platform=unix"
fi

pre_configure_target() {
  sed -e "s|LDFLAGS := -lz -lpthread -lFLAC -lmpg123 -ldl|& -L$(get_install_dir mpg123)/usr/lib|" \
    -i ${PKG_BUILD}/Makefile.libretro
}

makeinstall_target() {
  mkdir -p ${SYSROOT_PREFIX}/usr/lib/cmake/${PKG_NAME}
  cp ${PKG_LIBPATH} ${SYSROOT_PREFIX}/usr/lib/${PKG_LIBNAME}
  echo "set(${PKG_LIBVAR} ${SYSROOT_PREFIX}/usr/lib/${PKG_LIBNAME})" >${SYSROOT_PREFIX}/usr/lib/cmake/${PKG_NAME}/${PKG_NAME}-config.cmake

  cp -v capsimg.so ${SYSROOT_PREFIX}/usr/lib/
}
