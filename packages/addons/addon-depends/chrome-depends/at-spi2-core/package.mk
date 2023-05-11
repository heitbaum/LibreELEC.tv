# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2017 Escalade
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="at-spi2-core"
PKG_VERSION="2.48.3"
PKG_SHA256="37316df43ca9989ce539d54cf429a768c28bb38a0b34950beadd0421827edf55"
PKG_LICENSE="OSS"
PKG_SITE="https://www.gnome.org/"
PKG_URL="https://download.gnome.org/sources/at-spi2-core/${PKG_VERSION:0:4}/at-spi2-core-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain atk dbus glib"
PKG_LONGDESC="Protocol definitions and daemon for D-Bus at-spi."

configure_package() {
  # Build with x11 support
  if [ ${DISPLAYSERVER} = "x11" ]; then
    PKG_DEPENDS_TARGET+=" libXtst"
  fi
}

pre_configure_target() {
  PKG_MESON_OPTS_TARGET="-Ddocs=false \
                         -Dintrospection=disabled \
                         -Ddbus_daemon=/usr/bin/dbus-daemon"

  if [ ${DISPLAYSERVER} = "x11" ]; then
    PKG_MESON_OPTS_TARGET+="-Dx11=true"
    TARGET_LDFLAGS="${LDFLAGS} -lXext"
  else
    PKG_MESON_OPTS_TARGET+="-Dx11=false"
  fi
}
