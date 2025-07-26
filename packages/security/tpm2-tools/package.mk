# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="tpm2-tools"
PKG_VERSION="5.7"
PKG_SHA256="3810d36b5079256f4f2f7ce552e22213d43b1031c131538df8a2dbc3c570983a"
PKG_LICENSE="BSD-3-Clause"
PKG_SITE="https://tpm2-software.github.io"
PKG_URL="https://github.com/tpm2-software/tpm2-tools/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain tpm2-tss"
PKG_LONGDESC="Trusted Platform Module (TPM2.0) tools"
