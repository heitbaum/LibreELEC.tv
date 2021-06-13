# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="stress-ng"
PKG_VERSION="0.12.10"
PKG_SHA256="bd167b6559fa8a28680371b1defd3ffe2344eb550129d58dd7d5e2d568f2786e"
PKG_LICENSE="GPLv2"
PKG_SITE="https://kernel.ubuntu.com/~cking/stress-ng/"
PKG_URL="https://kernel.ubuntu.com/~cking/tarballs/stress-ng/stress-ng-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain attr keyutils libaio libcap zlib"
PKG_LONGDESC="stress-ng will stress test a computer system in various selectable ways"
PKG_BUILD_FLAGS="-sysroot"
