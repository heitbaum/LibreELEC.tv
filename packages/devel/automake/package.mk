# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="automake"
PKG_VERSION="1.16.3"
PKG_SHA256="ff2bf7656c4d1c6fdda3b8bebb21f09153a736bcba169aaf65eab25fa113bf3a"
PKG_LICENSE="GPL"
PKG_SITE="http://sources.redhat.com/automake/"
PKG_URL="http://ftpmirror.gnu.org/automake/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="ccache:host autoconf:host"
PKG_LONGDESC="A GNU tool for automatically creating Makefiles."

PKG_CONFIGURE_OPTS_HOST="--target=${TARGET_NAME} --disable-silent-rules"

post_makeinstall_host() {
  make prefix=${SYSROOT_PREFIX}/usr install
}
