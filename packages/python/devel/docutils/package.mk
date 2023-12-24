# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="docutils"
PKG_VERSION="0.20.1"
PKG_SHA256="f08a4e276c3a1583a86dce3e34aba3fe04d02bba2dd51ed16106244e8a923e3b"
PKG_LICENSE="Public Domain"
PKG_SITE="https://www.docutils.org"
PKG_URL="https://downloads.sourceforge.net/project/docutils/docutils/${PKG_VERSION}/docutils-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="Python3:host setuptools:host"
PKG_LONGDESC="Utilities for general- and special-purpose documentation"
PKG_TOOLCHAIN="manual"

makeinstall_host() {
  exec_thread_safe python3 setup.py install --prefix=${TOOLCHAIN}
}
