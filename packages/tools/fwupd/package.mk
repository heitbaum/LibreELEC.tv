# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="fwupd"
PKG_VERSION="2.0.12"
PKG_SHA256="83eab17ef2e65249491aef5e99419827b43ac56d40c5b0747b59ee94b147215e"
PKG_LICENSE="LGPL-2.1"
PKG_SITE="https://fwupd.org"
PKG_URL="https://github.com/fwupd/fwupd/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain gpgme libarchive libjcat libusb libxmlb sqlite xz"
PKG_LONGDESC="A system daemon to allow session software to update firmware"

PKG_MESON_OPTS_TARGET="-Dbuild=all \
                       -Ddocs=disabled \
                       -Defi_os_dir=libreelec \
                       -Dfirmware-packager=false \
                       -Dman=false \
                       -Dpassim=disabled \
                       -Dplugin_flashrom=disabled \
                       -Dplugin_uefi_capsule_splash=false \
                       -Dsupported_build=enabled \
                       -Dsystemd=disabled \
                       -Dtests=false \
                       -Dvendor_ids_dir=/usr/share/hwdata"

pre_configure_target() {
  export PKG_CONFIG_PATH="$(get_install_dir xz)/usr/lib/pkgconfig:${PKG_CONFIG_PATH}"
}

post_makeinstall_target() {
  echo "[fwupd]"            >  ${INSTALL}/etc/fwupd/fwupd.conf
  echo "EspLocation=/flash" >> ${INSTALL}/etc/fwupd/fwupd.conf
  chmod 640 ${INSTALL}/etc/fwupd/fwupd.conf

  #safe_remove ${INSTALL}/etc
  #safe_remove ${INSTALL}/usr/lib
}
