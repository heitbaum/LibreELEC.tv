#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

. ./config/options ""

PKG_VERSION="$(get_pkg_version podman-bin)"

unpack() {
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/llvm/llvm-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

TEMP_DIR=fg
mkdir -p ${TEMP_DIR}/{a,b}

tar --strip-components=1 -xf ${SOURCES}/podman-bin/podman-bin-${PKG_VERSION}.tar.gz -C ${TEMP_DIR}/a
tar --strip-components=1 -xf ${SOURCES}/podman-bin/podman-bin-${PKG_VERSION}.tar.gz -C ${TEMP_DIR}/b

cd ${TEMP_DIR}/b
find . -name "*.go" -print | \
  xargs sed -i \
    -e '/^\W*\/\// ! s#/etc/containers#/storage/.kodi/addons/service.system.podman/etc/containers#g' \
    -e '/^\W*\/\// ! s#/usr/share/containers#/storage/.kodi/userdata/addon_data/service.system.podman/podman/etc/containers#g' \
    -e '/^\W*\/\// ! s#/var/lib/containers#/storage/.kodi/userdata/addon_data/service.system.podman/podman#g'

cd .. #${TEMP_DIR}
pwd
diff -Nur a b > podman-0002-path-changes.patch || true
