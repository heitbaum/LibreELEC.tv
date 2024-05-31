# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="shairport-sync"
PKG_VERSION="4.3.3"
PKG_SHA256="444bf77fe495d11d0c3b8212ea7a6ae44d6b2084c3600cea0629497a3e5f0209"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/mikebrady/shairport-sync"
PKG_URL="https://github.com/mikebrady/shairport-sync/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib avahi ffmpeg libconfig libdaemon libgcrypt libplist libsndfile libsodium nqptp openssl popt pulseaudio soxr util-linux xxd:host"
PKG_LONGDESC="AirPlay audio player."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="-sysroot -cfg-libs"

PKG_CONFIGURE_OPTS_TARGET="--with-alsa \
                           --with-avahi \
                           --with-convolution \
                           --with-metadata \
                           --with-pa \
                           --with-pipe \
                           --with-pkg-config \
                           --with-soxr \
                           --with-ssl=openssl \
                           --with-stdout \
                           --without-configfiles \
                           --with-airplay-2"
