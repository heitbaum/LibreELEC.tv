# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="conmon"
PKG_VERSION="2.1.8"
PKG_SHA256="e72c090210a03ca3b43a0fad53f15bca90bbee65105c412468009cf3a5988325"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://github.com/containers/conmon"
PKG_URL="https://github.com/containers/conmon/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain glib libseccomp systemd"
PKG_LONGDESC="An OCI container runtime monitor"

# Git commit of the matching release https://github.com/containers/conmon
export PKG_GIT_COMMIT="f633919178f6c8ee4fb41b848a056ec33f8d707d"

pre_configure_target() {
  export PKG_CONFIG_PATH="$(get_install_dir libseccomp)/usr/lib/pkgconfig:${PKG_CONFIG_PATH}"
  export GIT_COMMIT=${PKG_GIT_COMMIT}
}
