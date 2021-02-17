# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2011 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="whois"
PKG_VERSION="5.5.8"
PKG_SHA256="e227dfc912271ebff5bc144782a8da680afed729f68e71d317591c33d6ae0eed"
PKG_LICENSE="GPL"
PKG_SITE="http://www.linux.it/~md/software/"
PKG_URL="https://github.com/rfc1036/whois/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A tool that queries the whois directory service for information pertaining to a particular domain name."
PKG_BUILD_FLAGS="-sysroot"

make_target() {
  make mkpasswd
}

makeinstall_target() {
  make install BASEDIR=${INSTALL}
}
