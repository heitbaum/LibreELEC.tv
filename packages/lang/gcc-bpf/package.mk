# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gcc-bpf"
PKG_VERSION="$(get_pkg_version gcc)"
PKG_LICENSE="GPL-2.0-or-later"
PKG_URL=""
PKG_DEPENDS_HOST="toolchain:host ccache:host autoconf:host binutils-bpf:host gmp:host mpfr:host mpc:host zstd:host"
PKG_LONGDESC="This package contains the GNU Compiler Collection for 64-bit ARM."
PKG_DEPENDS_UNPACK+=" gcc"
PKG_PATCH_DIRS+=" $(get_pkg_directory gcc)/patches"

if [ "${MOLD_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_HOST+=" mold:host"
fi

PKG_CONFIGURE_OPTS_HOST="--target=bpf \
                         --with-sysroot=${TOOLCHAIN}/bpf/sysroot \
                         --with-gmp=${TOOLCHAIN} \
                         --with-mpfr=${TOOLCHAIN} \
                         --with-mpc=${TOOLCHAIN} \
                         --with-zstd=${TOOLCHAIN} \
                         --with-gnu-as \
                         --with-gnu-ld \
                         --with-newlib \
                         --without-ppl \
                         --without-headers \
                         --without-cloog \
                         --enable-__cxa_atexit \
                         --enable-checking=release \
                         --enable-gold \
                         --enable-languages=c \
                         --enable-ld=default \
                         --enable-lto \
                         --enable-plugin \
                         --enable-static \
                         --disable-decimal-float \
                         --disable-gcov \
                         --disable-libada \
                         --disable-libatomic \
                         --disable-libgomp \
                         --disable-libitm \
                         --disable-libmpx \
                         --disable-libmudflap \
                         --disable-libquadmath \
                         --disable-libquadmath-support \
                         --disable-libsanitizer \
                         --disable-libssp \
                         --disable-multilib \
                         --disable-nls \
                         --disable-shared \
                         --disable-threads"

unpack() {
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/gcc/gcc-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

pre_configure_host() {
  unset CPPFLAGS
  unset CFLAGS
  unset CXXFLAGS
  unset LDFLAGS
}
