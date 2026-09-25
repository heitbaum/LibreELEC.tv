# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="uxplay"
PKG_VERSION="e3599e8c40ff1abe62146ba8a3e51c937bcf2524"
PKG_SHA256="b62b32ec09f3ca0b5e3e7d16930a5182d3a1df02ed87be31470bd22c65f6a097"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://github.com/FDH2/UxPlay"
PKG_URL="https://github.com/FDH2/UxPlay/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Airplay Unix mirroring server"
PKG_TOOLCHAIN="manual"

# source only: inputstream.airplay uses the lib folder
