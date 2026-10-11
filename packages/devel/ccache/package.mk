# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="ccache"
PKG_VERSION="4.14.1"
PKG_SHA256="29f10de481ac2c41c91bfabead63d803bd2fe823e09752aade5b0b8704cc4f30"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://ccache.dev/download.html"
PKG_URL="https://github.com/ccache/ccache/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="cmake:host make:host zstd:host libfmt:host xxHash:host"
PKG_LONGDESC="A compiler cache to speed up re-compilation of C/C++ code by caching."
# Override toolchain as ninja is not built yet
PKG_TOOLCHAIN="cmake-make"
PKG_BUILD_FLAGS="+local-cc"

# the prebuilt ccache:host published as ccache-reusable
if reusable_host_tool; then
  PKG_DEPENDS_HOST+=" ccache-reusable:host"
fi

configure_host() {
  local rpath=""

  # a reusable ccache finds libfmt, libxxhash and libzstd from $ORIGIN, leave
  # the toolchain path out
  if listcontains "${BUILD_REUSABLE}" "(all|ccache:host)"; then
    LDFLAGS="${LDFLAGS/-Wl,-rpath,${TOOLCHAIN}\/lib/}"
    rpath='$ORIGIN/../lib'
  fi

  # custom cmake build to override the LOCAL_CC/CXX
  cp ${CMAKE_CONF} cmake-ccache.conf

  echo "SET(CMAKE_C_COMPILER   ${CC})"  >>cmake-ccache.conf
  echo "SET(CMAKE_CXX_COMPILER ${CXX})" >>cmake-ccache.conf

  cmake -DCMAKE_TOOLCHAIN_FILE=cmake-ccache.conf \
        -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN} \
        -DENABLE_DOCUMENTATION=OFF \
        -DREDIS_STORAGE_BACKEND=OFF \
        -DENABLE_TESTING=OFF \
        -DDEPS=SYSTEM \
        -DCMAKE_INSTALL_RPATH="${rpath}" \
        ..
}

post_makeinstall_host() {
  if listcontains "${BUILD_REUSABLE}" "(all|ccache:host)"; then
    reusable_save_install
  fi

  setup_ccache_host
}
