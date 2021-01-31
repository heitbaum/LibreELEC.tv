# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2017 Escalade
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gtk3"
PKG_VERSION="3.24.24"
PKG_SHA256="cc9d4367c55b724832f6b09ab85481738ea456871f0381768a6a99335a98378a"
PKG_LICENSE="LGPL"
PKG_SITE="http://www.gtk.org/"
PKG_URL="https://ftp.gnome.org/pub/gnome/sources/gtk+/${PKG_VERSION:0:4}/gtk+-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain at-spi2-atk atk cairo gdk-pixbuf glib libX11 libXi libXrandr libepoxy pango gdk-pixbuf:host"
PKG_DEPENDS_CONFIG="libXft pango gdk-pixbuf shared-mime-info"
PKG_LONGDESC="A library for creating graphical user interfaces for the X Window System."
PKG_TOOLCHAIN="meson"
PKG_BUILD_FLAGS="-sysroot"

PKG_MESON_OPTS_TARGET="-Dbroadway_backend=false \
                       -Dcloudproviders=false \
                       -Dcolord=no \
                       -Ddemos=false \
                       -Dgtk_doc=false \
                       -Dintrospection=false \
                       -Dman=false \
                       -Dprint_backends=auto \
                       -Dquartz_backend=false \
                       -Dtests=false \
                       -Dwayland_backend=false \
                       -Dwin32_backend=false \
                       -Dxinerama=no \
                       -Dbuiltin_immodules=yes \
                       -Dx11_backend=true"

pre_configure_target() {
  # ${TOOLCHAIN}/bin/glib-compile-resources requires ${TOOLCHAIN}/lib/libffi.so.6
  # export XDG_DATA_DIRS=.../usr/share
  # -k0
  #  https://source.puri.sm/Librem5/OS-issues/-/issues/17
  #  https://www.linuxtopia.org/online_books/linux_desktop_guides/gnome_2.14_admin_guide/mimetypes-database.html
  export LD_LIBRARY_PATH="${TOOLCHAIN}/lib:${LD_LIBRARY_PATH}"
  export GLIB_COMPILE_RESOURCES=glib-compile-resources GLIB_MKENUMS=glib-mkenums GLIB_GENMARSHAL=glib-genmarshal

echo
echo hi
echo $LD_LIBRARY_PATH=
set
  export XDG_DATA_DIRS=${TOOLCHAIN}/share/:/usr/local/share/:/usr/share/
}
