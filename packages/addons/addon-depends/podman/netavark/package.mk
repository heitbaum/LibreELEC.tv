# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="netavark"
PKG_VERSION="1.12.0"
PKG_SHA256="796163b24b9fe69b9b1db3b08d43b02dd707de8af2abd42e381de70892cc2421"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://github.com/containers/netavark"
PKG_URL="https://github.com/containers/netavark/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain cargo:host protobuf:host"
PKG_LONGDESC="Container network stack"
