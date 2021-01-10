# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libdvdcss"
# From https://github.com/howie-f/libdvdcss/releases/tag/1.4.3-Matrix-Beta-2
PKG_VERSION="bc00dd5770eea1b71209c279f7af43a66a5327fd"
PKG_SHA256="976f373888dd782f74b97264799005a6817b43db3805e9d844b94980027a4fbe"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/xbmc/libdvdcss"
PKG_URL="https://github.com/xbmc/libdvdcss/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="libdvdcss is a simple library designed for accessing DVDs as a block device without having to bother about the decryption."
PKG_TOOLCHAIN="manual"
