# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="requests"
PKG_VERSION="2.31.0"
PKG_SHA256="942c5a758f98d790eaed1a29cb6eefc7ffb0d1cf7af05c3d2791656dbd6ad1e1"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://requests.readthedocs.io"
PKG_URL="https://github.com/psf/requests/releases/download/v${PKG_VERSION}/requests-${PKG_VERSION}.tar.gz"
#https://github.com/psf/requests/releases/download/v2.31.0/requests-2.31.0-py3-none-any.whl
PKG_DEPENDS_HOST="Python3:host setuptools:host"
PKG_LONGDESC="A simple, yet elegant, HTTP library."
PKG_TOOLCHAIN="manual"

makeinstall_host() {
  exec_thread_safe python3 setup.py install --prefix=${TOOLCHAIN}
}
