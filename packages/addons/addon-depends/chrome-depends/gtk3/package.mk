# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2017 Escalade
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gtk3"
PKG_VERSION="3.94.0"
PKG_SHA256="a947caa5296610b0f1d7a03b58df34765c227c577c78e683e75eea3251a67035"
PKG_LICENSE="LGPL"
PKG_SITE="http://www.gtk.org/"
PKG_URL="https://ftp.gnome.org/pub/gnome/sources/gtk+/${PKG_VERSION:0:4}/gtk+-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain at-spi2-atk atk cairo gdk-pixbuf glib libX11 libXi libXrandr libepoxy pango"
PKG_DEPENDS_CONFIG="libXft pango gdk-pixbuf shared-mime-info"
PKG_LONGDESC="A library for creating graphical user interfaces for the X Window System."
PKG_BUILD_FLAGS="-sysroot"

PKG_CONFIGURE_OPTS_TARGET="--disable-cups \
                           --disable-debug \
                           --enable-explicit-deps=no \
                           --disable-glibtest \
                           --disable-gtk-doc \
                           --disable-gtk-doc-html \
                           --disable-man \
                           --enable-modules \
                           --disable-papi \
                           --disable-xinerama \
                           --enable-xkb"

pre_configure_target() {
  # $TOOLCHAIN/bin/glib-compile-resources requires $TOOLCHAIN/lib/libffi.so.6
  export LD_LIBRARY_PATH="$TOOLCHAIN/lib:$LD_LIBRARY_PATH"
  export GLIB_COMPILE_RESOURCES=glib-compile-resources GLIB_MKENUMS=glib-mkenums GLIB_GENMARSHAL=glib-genmarshal
}
