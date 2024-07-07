# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="shairport-sync"
PKG_VERSION="4.3.4"
PKG_SHA256="3173cc54d06f6186a04509947697b56c7eac09c48153d7dea5f702042620a2df"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/mikebrady/shairport-sync"
PKG_URL="https://github.com/mikebrady/shairport-sync/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib avahi ffmpeg libconfig libdaemon libgcrypt libplist libsndfile libsodium nqptp openssl popt pulseaudio soxr util-linux xxd:host"
PKG_LONGDESC="AirPlay audio player."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="-sysroot"

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
