# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2014 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="openssl3"
PKG_VERSION="3.6.1"
PKG_SHA256="b1bfedcd5b289ff22aee87c9d600f515767ebf45f77168cb6d64f231f518a82e"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://openssl-library.org"
PKG_URL="https://github.com/openssl/openssl/releases/download/openssl-${PKG_VERSION}/openssl-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host"
PKG_DEPENDS_TARGET="autotools:host gcc:host"
PKG_LONGDESC="The Open Source toolkit for Secure Sockets Layer and Transport Layer Security"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_SHARED="--libdir=lib \
                           shared \
                           threads \
                           no-ec2m \
                           no-md2 \
                           no-rc5 \
                           no-rfc3779 \
                           no-sctp \
                           no-ssl-trace \
                           no-unit-test \
                           no-weak-ssl-ciphers \
                           no-zlib \
                           no-zlib-dynamic"

PKG_CONFIGURE_OPTS_TARGET="--prefix=/usr \
                           --openssldir=/etc/ssl"

post_unpack() {
  find ${PKG_BUILD}/apps -type f | xargs -n 1 -t sed 's|./demoCA|/etc/ssl|' -i
}

pre_configure_target() {
  mkdir -p ${PKG_BUILD}/.${TARGET_NAME}
  cp -a ${PKG_BUILD}/* ${PKG_BUILD}/.${TARGET_NAME}/

  case ${TARGET_ARCH} in
    x86_64)
      OPENSSL_TARGET=linux-x86_64
      PLATFORM_FLAGS=enable-ec_nistp_64_gcc_128
      ;;
    arm)
      OPENSSL_TARGET=linux-armv4
      ;;
    aarch64)
      OPENSSL_TARGET=linux-aarch64
      ;;
    riscv64)
      OPENSSL_TARGET=linux-generic64
      ;;
  esac
}

configure_target() {
  cd ${PKG_BUILD}/.${TARGET_NAME}
  ./Configure ${PKG_CONFIGURE_OPTS_TARGET} ${PKG_CONFIGURE_OPTS_SHARED} ${PLATFORM_FLAGS} ${OPENSSL_TARGET} ${CFLAGS} ${LDFLAGS}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib
  cp -p ${PKG_BUILD}/.${TARGET_NAME}/{libssl.so.3,libcrypto.so.3} ${INSTALL}/usr/lib
  cp -p ${PKG_BUILD}/.${TARGET_NAME}/{libssl.so.3,libcrypto.so.3} ${SYSROOT_PREFIX}/usr/lib
}
