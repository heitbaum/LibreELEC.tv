# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="glycin"
PKG_VERSION="2.1.1"
PKG_SHA256="ce7044dea45e23e4cf7b2dca4d39a875865e761268944d22376778f8df474c6c"
PKG_LICENSE="OSS"
PKG_SITE="http://www.gtk.org/"
PKG_URL="https://gitlab.gnome.org/GNOME/glycin/-/archive/${PKG_VERSION}/glycin-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain cargo:host fontconfig libseccomp lcms2 glib"
PKG_DEPENDS_CONFIG="libseccomp"
PKG_LONGDESC="Sandboxed and extendable image loading"
PKG_BUILD_FLAGS="-sysroot"
PKG_TOOLCHAIN="manual"

make_target() {
  cargo build \
    --target ${TARGET_NAME} \
    --release \
    --locked \
    -p libglycin
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/pkgconfig ${INSTALL}/usr/include/glycin-2
  cp ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/libglycin.so \
    ${INSTALL}/usr/lib/libglycin-2.so

  cp ${PKG_BUILD}/libglycin/include/glycin.h ${INSTALL}/usr/include/glycin-2/glycin.h

  cat > "${INSTALL}/usr/lib/pkgconfig/glycin-2.pc" << EOF
prefix=/usr
includedir=\${prefix}/include
libdir=\${prefix}/lib

Name: glycin-2
Description: Glycin: Sandboxed and extendable image decoding
Version: ${PKG_VERSION}
Libs: -L\${libdir} -lglycin-2
Cflags: -I\${includedir}/glycin-2
EOF
}
