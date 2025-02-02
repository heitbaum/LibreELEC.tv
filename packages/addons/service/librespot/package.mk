# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2017 Shane Meagher (shanemeagher)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="librespot"
PKG_VERSION="471735aa5a27a1a1ebed16740624366ce8c3caa9"
PKG_VERSION_DATE="2023-12-06"
PKG_SHA256="6e74ac2278383a13e9304a0bc96d12a8ece57963ce93d3ad39db91eea2bb678c"
PKG_REV="4"
PKG_ARCH="any"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/librespot-org/librespot/"
PKG_URL="https://github.com/librespot-org/librespot/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib avahi pulseaudio bindgen-cli:host cargo:host cmake:host"
PKG_SECTION="service"
PKG_SHORTDESC="Librespot: play Spotify through Kodi using a Spotify app as a remote"
PKG_LONGDESC="Librespot (${PKG_VERSION_DATE}) lets you play Spotify through Kodi using a Spotify app as a remote."
PKG_TOOLCHAIN="manual"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="Librespot"
PKG_ADDON_TYPE="xbmc.service"
PKG_MAINTAINER="Anton Voyl (awiouy)"

make_target() {
  # build of the crate aws-lc-rs fails when CMAKE is set. Set the required toolchain.
  unset CMAKE
  export CMAKE_TOOLCHAIN_FILE="${CMAKE_CONF}"
  export CMAKE_INSTALL_PREFIX="/usr"

  export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=${SYSROOT_PREFIX}"
  export RUSTC_LINKER=${CC}
  cargo build \
    --target ${TARGET_NAME} \
    --release \
    --no-default-features \
    --features "alsa-backend pulseaudio-backend with-dns-sd"

  ${STRIP} ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/librespot
}

addon() {
  mkdir -p ${ADDON_BUILD}/${PKG_ADDON_ID}/bin
    cp ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/librespot \
       ${ADDON_BUILD}/${PKG_ADDON_ID}/bin
    patchelf --add-rpath '${ORIGIN}/../lib.private' ${ADDON_BUILD}/${PKG_ADDON_ID}/bin/librespot

  mkdir -p ${ADDON_BUILD}/${PKG_ADDON_ID}/lib.private
    cp $(get_build_dir avahi)/avahi-compat-libdns_sd/.libs/libdns_sd.so.1 \
       ${ADDON_BUILD}/${PKG_ADDON_ID}/lib.private
}
