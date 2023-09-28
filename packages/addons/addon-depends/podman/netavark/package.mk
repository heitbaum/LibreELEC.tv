# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="netavark"
PKG_VERSION="1.8.0"
PKG_SHA256="b1422ef6927458e9f80f7d322b751e29ab5d04d8ed6cb065baa82fa4291af10f"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://github.com/containers/netavark"
PKG_URL="https://github.com/containers/netavark/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain cargo:host protobuf:host"
PKG_LONGDESC="Container network stack"
