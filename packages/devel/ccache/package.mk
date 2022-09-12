# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="ccache"
PKG_VERSION="4.6.3"
PKG_SHA256="1e3a251bb112632553b8255a78661fe526c3a16598496d51128c32b218fd8b22"
PKG_LICENSE="GPL"
PKG_SITE="https://ccache.dev/download.html"
PKG_URL="https://github.com/ccache/ccache/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="cmake:host make:host zstd:host"
PKG_LONGDESC="A compiler cache to speed up re-compilation of C/C++ code by caching."
# Override toolchain as ninja is not built yet
PKG_TOOLCHAIN="cmake-make"

configure_host() {
  # custom cmake build to override the LOCAL_CC/CXX
  setup_toolchain host:cmake-make
  cp ${CMAKE_CONF} cmake-ccache.conf

  echo "SET(CMAKE_C_COMPILER   $LOCAL_CC)"  >> cmake-ccache.conf
  echo "SET(CMAKE_CXX_COMPILER $LOCAL_CXX)" >> cmake-ccache.conf

  cmake -DCMAKE_TOOLCHAIN_FILE=cmake-ccache.conf \
        -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN} \
        -DZSTD_FROM_INTERNET=OFF \
        -DREDIS_STORAGE_BACKEND=OFF \
        ..
}

make_host() {
  :
}

post_makeinstall_host() {
# setup ccache
  if [ -z "${CCACHE_DISABLE}" ]; then
    ${TOOLCHAIN}/bin/ccache --max-size=${CCACHE_CACHE_SIZE}
    ${TOOLCHAIN}/bin/ccache --set-config compression_level=${CCACHE_COMPRESSLEVEL}
    ${TOOLCHAIN}/bin/ccache --set-config compression=${CCACHE_COMPRESSION}
    ${TOOLCHAIN}/bin/ccache --set-config disable=false
  else
    ${TOOLCHAIN}/bin/ccache --set-config disable=true
  fi

  cat > ${TOOLCHAIN}/bin/host-gcc <<EOF
#!/bin/sh
${TOOLCHAIN}/bin/ccache ${LOCAL_CC} "\$@"
EOF

  chmod +x ${TOOLCHAIN}/bin/host-gcc

  cat > ${TOOLCHAIN}/bin/host-g++ <<EOF
#!/bin/sh
${TOOLCHAIN}/bin/ccache ${LOCAL_CXX} "\$@"
EOF

  chmod +x ${TOOLCHAIN}/bin/host-g++
}
