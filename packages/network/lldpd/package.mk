# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="lldpd"
PKG_VERSION="a75be4bb3a2edbba1e93e942baac93d48eb115e4"
PKG_SHA256="eb65912e023a1c009ca7878fce19e25ce320da302199b63209ad1cf9052e696f"
PKG_LICENSE="ISC"
PKG_SITE="https://github.com/lldpd/lldpd"
PKG_URL="https://github.com/lldpd/lldpd/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="implementation of IEEE 802.1ab (LLDP)"
PKG_DEPENDS_TARGET="toolchain libcap libevent"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_TARGET="export \
                           --with-sysroot=${SYSROOT_PREFIX} \
                           --localstatedir=/var \
                           --runstatedir=/run \
                           --with-privsep-chroot=/run/lldpd/chroot \
                           --with-lldpd-ctl-socket=/run/lldpd/socket \
                           --with-lldpd-pid-file=/run/lldpd/pid \
			   --without-embedded-libevent \
			   --with-readline=no \
	                   --prefix=/usr \
                           --sysconfdir=/etc \
	                   --disable-privsep \
	                   --with-privsep-user=_lldpd \
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
