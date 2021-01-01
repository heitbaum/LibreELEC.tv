# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="shared-mime-info"
PKG_VERSION="2.1"
PKG_VERSION="1.15"
PKG_SHA256="b2d40cfcdd84e835d0f2c9107b3f3e77e9cf912f858171fe779946da634e8563"
PKG_SHA256="f482b027437c99e53b81037a9843fccd549243fd52145d016e9c7174a4f5db90"
PKG_LICENSE="GPL2"
PKG_SITE="https://freedesktop.org/wiki/Software/shared-mime-info/"
PKG_URL="https://gitlab.freedesktop.org/xdg/shared-mime-info/uploads/0ee50652091363ab0d17e335e5e74fbe/shared-mime-info-2.1.tar.xz"
PKG_URL="https://gitlab.freedesktop.org/xdg/shared-mime-info/uploads/b27eb88e4155d8fccb8bb3cd12025d5b/shared-mime-info-1.15.tar.xz"
#PKG_URL="http://freedesktop.org/~hadess/shared-mime-info-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain glib libxml2 gettext itstool:host"
PKG_LONGDESC="The shared-mime-info package contains the core database of common types."
PKG_BUILD_FLAGS="-parallel -sysroot"


PKG_MESON_OPTS_TARGET="-Dupdate-mimedb=false"
