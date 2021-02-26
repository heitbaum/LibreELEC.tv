# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="pcsc-lite"
PKG_VERSION="1.9.1"
PKG_SHA256="73c4789b7876a833a70f493cda21655dfe85689d9b7e29701c243276e55e683a"
PKG_LICENSE="GPL"
PKG_SITE="https://pcsclite.apdu.fr"
PKG_URL="https://pcsclite.apdu.fr/files/pcsc-lite-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain libusb"
PKG_LONGDESC="Middleware to access a smart card using SCard API (PC/SC)."

PKG_CONFIGURE_OPTS_TARGET="--disable-shared \
            --enable-static \
            --disable-libudev \
            --enable-libusb \
            --enable-usbdropdir=/storage/.kodi/addons/service.pcscd/drivers"
