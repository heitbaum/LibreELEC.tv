# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gcc-or1k"
PKG_VERSION="$(get_pkg_version gcc)"
PKG_LICENSE="GPL-3.0-or-later"
PKG_URL=""
PKG_DEPENDS_HOST="toolchain:host ccache:host autoconf:host binutils-or1k:host gmp:host mpfr:host mpc:host zstd:host"
PKG_LONGDESC="This package contains the GNU Compiler Collection for OpenRISC 1000."
PKG_DEPENDS_UNPACK+=" gcc"
PKG_PATCH_DIRS+=" $(get_pkg_directory gcc)/patches"

if [ "${MOLD_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_HOST+=" mold:host"
fi

# the prebuilt binutils-or1k:host and gcc-or1k:host published as or1k-reusable,
# named after a hash of their recipes and of the gcc and binutils recipes they
# are built from, so that a stale archive is never used
if [ "${USE_REUSABLE}" = "yes" -o "${USE_REUSABLE}" = "preferred" ] ||
   listcontains "${BUILD_REUSABLE}" "(all|gcc-or1k:host)"; then
  PKG_REUSABLE_HASH="$(get_reusable_inputs_hash gcc-or1k binutils-or1k gcc binutils)"
  PKG_REUSABLE_VERSION="${OS_VERSION}-${PKG_VERSION}"
  PKG_REUSABLE_SOURCE_NAME="or1k-reusable-${PKG_REUSABLE_VERSION}-${MACHINE_HARDWARE_NAME}-${PKG_REUSABLE_HASH}.tar.xz"
  PKG_REUSABLE_URL="${REUSABLE_URL}/or1k-${PKG_REUSABLE_VERSION}/${PKG_REUSABLE_SOURCE_NAME}"
fi

# preferred falls back to building gcc-or1k:host when no reusable archive is available
if [ "${USE_REUSABLE}" = "yes" ] ||
   { [ "${USE_REUSABLE}" = "preferred" ] &&
     [ -n "$(get_reusable_sha256 or1k-reusable ${PKG_REUSABLE_SOURCE_NAME} ${PKG_REUSABLE_URL})" ]; }; then
  # gcc-or1k then only pulls in the archive, and binutils-or1k is not built
  PKG_REUSABLE="yes"
  PKG_SECTION="virtual"
  PKG_DEPENDS_HOST="or1k-reusable:host"
  PKG_DEPENDS_UNPACK=""
  PKG_SKIP_PATCHES="yes"
elif listcontains "${BUILD_REUSABLE}" "(all|gcc-or1k:host)"; then
  PKG_DEPENDS_HOST+=" patchelf:host"
fi

PKG_CONFIGURE_OPTS_HOST="--target=or1k-none-elf \
                         --with-sysroot=${TOOLCHAIN}/or1k-none-elf/sysroot \
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
  # scripts/unpack still calls this for a virtual package
  [ "${PKG_REUSABLE}" = "yes" ] && return 0

  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/gcc/gcc-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

pre_configure_host() {
  unset CPPFLAGS
  unset CFLAGS
  unset CXXFLAGS
  unset LDFLAGS
}

post_makeinstall_host() {
  if listcontains "${BUILD_REUSABLE}" "(all|gcc-or1k:host)"; then
    save_or1k_reusable
  fi

  PKG_GCC_PREFIX="${TOOLCHAIN}/bin/or1k-none-elf-"
  GCC_VERSION=$(${PKG_GCC_PREFIX}gcc -dumpversion)
  DATE="0501$(echo ${GCC_VERSION} | sed 's/\./0/g')"
  CROSS_CC=${PKG_GCC_PREFIX}gcc-${GCC_VERSION}

  rm -f ${PKG_GCC_PREFIX}gcc

  cat >${PKG_GCC_PREFIX}gcc <<EOF
#!/bin/sh
${TOOLCHAIN}/bin/ccache ${CROSS_CC} "\$@"
EOF

  chmod +x ${PKG_GCC_PREFIX}gcc

  # To avoid cache trashing
  touch -c -t ${DATE} ${CROSS_CC}
}

# pack binutils-or1k:host and gcc-or1k:host as the or1k-reusable archive. The
# ccache wrapper names the toolchain, so the archive carries the compiler and
# or1k-reusable writes the wrapper again
save_or1k_reusable() {
  local stage="${PKG_BUILD}/.reusable/stage"
  local dir="${PKG_BUILD}/.reusable/or1k-reusable-${PKG_REUSABLE_VERSION}"

  rm -rf "${PKG_BUILD}/.reusable"
  make -C "$(get_build_dir binutils-or1k)/.${HOST_NAME}" MAKEINFO=true install DESTDIR="${stage}"
  make install DESTDIR="${stage}"
  mv "${stage}${TOOLCHAIN}" "${dir}"
  rm -rf "${stage}"

  reusable_make_relocatable "${dir}"

  {
    echo "archive: ${PKG_REUSABLE_SOURCE_NAME}"
    echo "host: ${MACHINE_HARDWARE_NAME}"
    echo "gcc: ${PKG_VERSION}"
    echo "binutils: $(get_pkg_version binutils)"
  } >"${dir}/MANIFEST"

  save_reusable or1k-reusable "${PKG_REUSABLE_SOURCE_NAME}" "${dir}"
}
