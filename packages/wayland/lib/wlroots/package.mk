# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="wlroots"
PKG_VERSION="0.19.0-rc2"
PKG_SHA256="5089d42112e89609d9c80176bcb84f6be1d1f0665e2f35295d77c43b05849db6"
PKG_LICENSE="MIT"
PKG_SITE="https://gitlab.freedesktop.org/wlroots/wlroots/"
PKG_URL="https://gitlab.freedesktop.org/wlroots/wlroots/-/archive/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain hwdata libdisplay-info libinput libxkbcommon pixman libdrm wayland wayland-protocols seatd"
PKG_LONGDESC="A modular Wayland compositor library"

configure_package() {
  # OpenGLES Support
  if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  fi
}

PKG_MESON_OPTS_TARGET="-Dxcb-errors=disabled \
                       -Dxwayland=disabled \
                       -Dbackends=drm,libinput \
                       -Dexamples=false \
                       -Drenderers=gles2"

pre_configure_target() {
  # wlroots does not build without -Wno flags as all warnings being treated as errors
  export TARGET_CFLAGS=$(echo "${TARGET_CFLAGS} -Wno-unused-variable -Wno-unused-but-set-variable -Wno-unused-function")
}
