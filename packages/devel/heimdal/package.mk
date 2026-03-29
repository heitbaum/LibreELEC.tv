# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2017 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="heimdal"
PKG_VERSION="abd35b246a7ab3b304c3ca918e52240154b87008"
PKG_SHA256="9a17b393c27d1ef1387787e535250995decffb22339b8269427a670a6afb820d"
PKG_LICENSE="BSD-3c"
PKG_SITE="http://www.h5l.org/"
PKG_URL="https://github.com/heimdal/heimdal/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="autotools:host Python3:host ncurses:host asn1c:host flex:host"
PKG_LONGDESC="Kerberos 5, PKIX, CMS, GSS-API, SPNEGO, NTLM, Digest-MD5 and, SASL implementation."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="-parallel"

PKG_CONFIGURE_OPTS_HOST="ac_cv_prog_COMPILE_ET=no \
                         --enable-static --disable-shared \
                         --without-openldap \
                         --without-capng \
                         --without-sqlite3 \
                         --without-libintl \
                         --without-berkeley-db \
                         --without-readline \
                         --without-libedit \
                         --without-hesiod \
                         --without-x \
                         --disable-otp \
                         --disable-heimdal-documentation"

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/{bin,lib}
#    cp -PL lib/roken/.libs/libroken.so.19 ${TOOLCHAIN}/lib
#    cp -PR lib/asn1/.libs/asn1_compile ${TOOLCHAIN}/bin/heimdal_asn1_compile
#    cp -PR lib/com_err/.libs/compile_et ${TOOLCHAIN}/bin/heimdal_compile_et
#    patchelf --add-rpath '${ORIGIN}/../lib' ${TOOLCHAIN}/bin/{heimdal_asn1_compile,heimdal_compile_et}
}
