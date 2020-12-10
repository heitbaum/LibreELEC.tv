# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="lldpd"
PKG_VERSION="1.0.7"
PKG_SHA256="5c42956aa7c9af6337bb2b47d0c2ced2dad41ec99abea069ba7852913baf9aa0"
PKG_LICENSE="ISC"
PKG_SITE="https://github.com/lldpd/lldpd"
PKG_URL="https://github.com/lldpd/lldpd/archive/$PKG_VERSION.tar.gz"
PKG_LONGDESC="implementation of IEEE 802.1ab (LLDP)"
PKG_DEPENDS_TARGET="toolchain libevent"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_TARGET="export \
                           --with-sysroot=$SYSROOT_PREFIX \
                           --localstatedir=/var \
			   --without-embedded-libevent \
	                   --prefix=/usr \
                           --sysconfdir=/etc \
	                   --with-privsep-user=_lldpd
                           --with-privsep-group=_lldpd"

pre_configure_target() {
  ./autogen.sh
}
  
post_install() {
  add_user _lldpd x 347 347 "lldpd" "/var/run/lldpd" "/usr/sbin/nologin"
  add_group _lldpd 347

  enable_service lldpd.service
}
