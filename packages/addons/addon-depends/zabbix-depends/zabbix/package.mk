# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="zabbix"
PKG_VERSION="5.4.9"
PKG_VERSION="6.0.0beta3"
PKG_SHA256="baa11bfcfe54f35fdb3f28f401f89e4a93e2ec96bb27f0ce30c0c2a7b60f8b27"
PKG_REV="100"
PKG_ARCH="any"
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://www.zabbix.com"
PKG_URL="https://cdn.zabbix.com/${PKG_NAME}/sources/stable/$(get_pkg_version_maj_min)/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_URL="https://cdn.zabbix.com/${PKG_NAME}/sources/development/$(get_pkg_version_maj_min)/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain curl libevent libssh2 pcre sqlite zlib"
PKG_SECTION="service"
PKG_LONGDESC="Zabbix is an enterprise-class open source distributed monitoring solution."

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="Zabbix"
PKG_ADDON_TYPE="xbmc.service"

configure_package() {
  TARGET_CONFIGURE_OPTS="--host=${TARGET_NAME} \
                         --build=${HOST_NAME}"
  PKG_CONFIGURE_OPTS_TARGET="--enable-agent \
                             --enable-proxy \
                             --prefix=/storage/.kodi/addons/${PKG_ADDON_ID} \
                             --bindir=/storage/.kodi/addons/${PKG_ADDON_ID}/bin \
                             --libdir=/storage/.kodi/addons/${PKG_ADDON_ID}/lib \
                             --libexecdir=/storage/.kodi/addons/${PKG_ADDON_ID}/lib \
                             --sbindir=/storage/.kodi/addons/${PKG_ADDON_ID}/sbin \
                             --sysconfdir=/storage/.kodi/userdata/addon_data/${PKG_ADDON_ID}/etc \
                             --localstatedir=/var \
                             --runstatedir=/var/run \
                             --with-libevent=${SYSROOT_PREFIX}/usr \
                             --with-libpcre=${SYSROOT_PREFIX}/usr \
                             --with-openssl=${SYSROOT_PREFIX}/usr \
                             --with-sqlite3=${SYSROOT_PREFIX}/usr \
                             --with-zlib=${SYSROOT_PREFIX}/usr"
                             #--with-net-snmp 
                             #--enable-static
                             #--with-sqlite3=$(get_install_dir sqlite)/usr
                             #--with-libcurl=${TOOLCHAIN}/x86_64-libreelec-linux-gnu/sysroot/usr
                             #--with-ssh2=${TOOLCHAIN}/x86_64-libreelec-linux-gnu/sysroot/usr 
                             #--with-openipmi
}

addon() {
  mkdir -p ${ADDON_BUILD}/${PKG_ADDON_ID}/lib
  cp -r ${PKG_INSTALL}/storage/.kodi/addons/${PKG_ADDON_ID}/bin \
        ${PKG_INSTALL}/storage/.kodi/addons/${PKG_ADDON_ID}/sbin \
        ${PKG_INSTALL}/storage/.kodi/userdata/addon_data/${PKG_ADDON_ID}/etc \
          ${ADDON_BUILD}/${PKG_ADDON_ID}/
}
