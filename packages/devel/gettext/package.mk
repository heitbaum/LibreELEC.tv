# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gettext"
PKG_VERSION="1.0"
PKG_SHA256="71132a3fb71e68245b8f2ac4e9e97137d3e5c02f415636eb508ae607bc01add7"
PKG_LICENSE="GPL-3.0-or-later AND LGPL-2.1-or-later"
PKG_SITE="https://www.gnu.org/s/gettext/"
PKG_URL="https://ftp.gnu.org/pub/gnu/gettext/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="make:host"
PKG_DEPENDS_TARGET="autotools:host make:host gcc:host libxml2"
PKG_LONGDESC="A program internationalization library and tools."
PKG_BUILD_FLAGS="+local-cc"

PKG_CONFIGURE_OPTS_COMMON="--disable-rpath \
                           --disable-modula2"

PKG_CONFIGURE_OPTS_HOST="${PKG_CONFIGURE_OPTS_COMMON} \
                         --disable-static --enable-shared \
                         --with-gnu-ld \
                         --disable-java \
                         --disable-curses \
                         --with-included-libxml \
                         --disable-native-java \
                         --disable-csharp \
                         --without-emacs"

# the prebuilt gettext:host published as gettext-reusable, named after a hash
# of the recipe so that a stale archive is never used
if [ "${USE_REUSABLE}" = "yes" -o "${USE_REUSABLE}" = "preferred" ] ||
   listcontains "${BUILD_REUSABLE}" "(all|gettext:host)"; then
  PKG_REUSABLE_HASH="$(get_reusable_inputs_hash gettext)"
  PKG_REUSABLE_VERSION="${OS_VERSION}-${PKG_VERSION}"
  PKG_REUSABLE_SOURCE_NAME="gettext-reusable-${PKG_REUSABLE_VERSION}-${MACHINE_HARDWARE_NAME}-${PKG_REUSABLE_HASH}.tar.xz"
  PKG_REUSABLE_URL="${REUSABLE_URL}/gettext-${PKG_REUSABLE_VERSION}/${PKG_REUSABLE_SOURCE_NAME}"
fi

# preferred falls back to building gettext:host when no reusable archive is available
if [ "${USE_REUSABLE}" = "yes" ] ||
   { [ "${USE_REUSABLE}" = "preferred" ] &&
     [ -n "$(get_reusable_sha256 gettext-reusable ${PKG_REUSABLE_SOURCE_NAME} ${PKG_REUSABLE_URL})" ]; }; then
  # gettext:host then only pulls in the archive, gettext is still built
  PKG_REUSABLE="yes"
  PKG_DEPENDS_HOST="make:host gettext-reusable:host"
elif listcontains "${BUILD_REUSABLE}" "(all|gettext:host)"; then
  # the tools then find their data relative to where they are installed
  PKG_CONFIGURE_OPTS_HOST+=" --enable-relocatable"
fi

PKG_CONFIGURE_OPTS_TARGET="${PKG_CONFIGURE_OPTS_COMMON} \
                           --disable-curses \
                           --disable-xattr \
                           --with-libxml2-prefix=${SYSROOT_PREFIX}/usr \
                           --with-sysroot=yes"

post_configure_target() {
  libtool_remove_rpath gettext-runtime/libasprintf/libtool
  libtool_remove_rpath gettext-tools/libtool
}

pre_configure_host() {
  # a relocatable gettext finds its libraries relative to $ORIGIN, so leave
  # the toolchain path out of a reusable gettext
  if listcontains "${BUILD_REUSABLE}" "(all|gettext:host)"; then
    LDFLAGS="${LDFLAGS/-Wl,-rpath,${TOOLCHAIN}\/lib/}"
  fi
}

post_makeinstall_host() {
  if listcontains "${BUILD_REUSABLE}" "(all|gettext:host)"; then
    save_gettext_reusable
  fi
}

# pack gettext:host as the gettext-reusable archive
save_gettext_reusable() {
  local stage="${PKG_BUILD}/.reusable/stage"
  local dir="${PKG_BUILD}/.reusable/gettext-reusable-${PKG_REUSABLE_VERSION}"

  rm -rf "${PKG_BUILD}/.reusable"
  make install DESTDIR="${stage}"
  mv "${stage}${TOOLCHAIN}" "${dir}"
  rm -rf "${stage}" "${dir}/share/doc" "${dir}/share/man" "${dir}/share/info"

  # patchelf is not built yet to fix an rpath, so none may name the toolchain
  if find "${dir}" -type f -exec readelf -d {} \; 2>/dev/null |
       grep -E "R(UN)?PATH" | grep -qF "${TOOLCHAIN}"; then
    die "gettext-reusable has an rpath into ${TOOLCHAIN}"
  fi

  reusable_make_relocatable "${dir}"

  {
    echo "archive: ${PKG_REUSABLE_SOURCE_NAME}"
    echo "host: ${MACHINE_HARDWARE_NAME}"
    echo "gettext: ${PKG_VERSION}"
  } >"${dir}/MANIFEST"

  save_reusable gettext-reusable "${PKG_REUSABLE_SOURCE_NAME}" "${dir}"
}

# with gettext-reusable there is nothing to build for gettext:host. Defined
# last so that they replace the host steps above.
if [ "${PKG_REUSABLE}" = "yes" ]; then
  pre_configure_host() { :; }
  configure_host() { :; }
  make_host() { :; }
  makeinstall_host() { :; }
  post_makeinstall_host() { :; }
fi
