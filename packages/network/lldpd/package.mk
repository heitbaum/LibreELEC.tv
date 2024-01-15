# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="lldpd"
PKG_VERSION="1.0.18"
PKG_SHA256="e2ea97b4387165c768161626a370979baa977e3d3a43fe75bb05d2f76aa825ad"
PKG_LICENSE="ISC"
PKG_SITE="https://github.com/lldpd/lldpd"
PKG_URL="https://github.com/lldpd/lldpd/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="implementation of IEEE 802.1ab (LLDP)"
PKG_DEPENDS_TARGET="toolchain libevent"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_TARGET="export \
                           --with-sysroot=${SYSROOT_PREFIX} \
                           --localstatedir=/var \
			   --without-embedded-libevent \
			   --with-readline=no \
	                   --prefix=/usr \
                           --sysconfdir=/etc \
	                   --with-privsep-user=_lldpd
                           --with-privsep-group=_lldpd"

pre_configure_target() {
  ./autogen.sh
}

post_configure_target() {
  sed -i 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' libtool
  sed -i 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool
}

post_install() {
  add_user _lldpd x 347 347 "lldpd" "/var/run/lldpd" "/usr/sbin/nologin"
  add_group _lldpd 347

  enable_service lldpd.service
}
