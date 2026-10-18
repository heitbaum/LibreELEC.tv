# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="lxml"
PKG_VERSION="7.0.0b1"
PKG_SHA256="c28385c1834aae143367c1251fbdc17fdf6aefbd5d33521778d31dca06286ebc"
PKG_LICENSE="BSD-3-Clause"
PKG_SITE="https://lxml.de"
PKG_URL="https://github.com/lxml/lxml/releases/download/${PKG_NAME}-${PKG_VERSION}-1/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="Python3:host libxml2:host libxslt:host setuptools:host"
PKG_LONGDESC="The lxml XML toolkit for Python"
PKG_TOOLCHAIN="python"
