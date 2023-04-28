# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="usbmuxd"
PKG_VERSION="049877e1f7a54f63fef12dd384c9a22fb38b3514"
PKG_SHA256="80edd61ca3040433824dd19bed4161514ce6e4a818ad0e7c9e98801811de5bd1"
PKG_REV="0"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://www.libimobiledevice.org"
PKG_URL="https://github.com/libimobiledevice/usbmuxd/releases/download/${PKG_VERSION}/usbmuxd-${PKG_VERSION}.tar.bz2"
PKG_URL="https://github.com/libimobiledevice/usbmuxd/archive/refs/heads/master.tar.gz"
PKG_DEPENDS_TARGET="toolchain libusb libimobiledevice libimobiledevice-glue libusbmuxd libplist"
PKG_TOOLCHAIN="autotools"
PKG_SECTION="service"
PKG_SHORTDESC="USB Multiplex Daemon"
PKG_LONGDESC="USB Multiplex Daemon"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="iPhone Tether"
PKG_ADDON_TYPE="xbmc.service"

PKG_DISCLAIMER="Additional data charges may occur. The LibreELEC team doesn't take any resposibility for extra data charges."

PKG_CONFIGURE_OPTS_TARGET="ac_cv_func_malloc_0_nonnull=yes \
                           ac_cv_func_realloc_0_nonnull=yes"

makeinstall_target() {
  :
}

addon() {
  mkdir -p ${ADDON_BUILD}/${PKG_ADDON_ID}/bin
    cp -P ${PKG_BUILD}/.${TARGET_NAME}/src/usbmuxd ${ADDON_BUILD}/${PKG_ADDON_ID}/bin/
}
