# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2017 Escalade
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="cups"
PKG_VERSION="2.4.9"
PKG_SHA256="b01fe197e9e81c1516412c73c782f5d9fef671ce998e3ee207cdf6e09155b76f"
PKG_LICENSE="GPL"
PKG_SITE="http://www.cups.org"
PKG_URL="https://github.com/openprinting/cups/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain gnutls zlib"
PKG_LONGDESC="CUPS printing system."
PKG_BUILD_FLAGS="+pic -sysroot"

PKG_CONFIGURE_OPTS_TARGET="--libdir=/usr/lib \
                           --disable-gssapi \
                           --with-dnssd=no \
                           --with-tls=gnutls
                           --disable-unit-tests"

pre_configure_target() {
  cd ..
  rm -rf .${TARGET_NAME}
}

makeinstall_target() {
  make BUILDROOT="${INSTALL}" install
}
