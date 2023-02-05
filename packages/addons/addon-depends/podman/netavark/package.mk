# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="netavark"
PKG_VERSION="1.9.0"
PKG_SHA256="9ec50b715ded0a0699134c001656fdd1411e3fb5325d347695c6cb8cc5fcf572"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://github.com/containers/netavark"
PKG_URL="https://github.com/containers/netavark/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain cargo:host protobuf:host"
PKG_LONGDESC="Container network stack"
