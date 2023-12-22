# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="packaging"
PKG_VERSION="23.2"
PKG_SHA256="16356d6984018e2039ac16b757a33c557124461af3b8368b9849a450d44b7c99"
PKG_LICENSE="Apache"
PKG_SITE="https://github.com/pypa/packaging"
PKG_URL="https://github.com/pypa/packaging/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="Python3:host setuptools:host"
PKG_LONGDESC="Core utilities for Python packages"
PKG_TOOLCHAIN="manual"

makeinstall_host() {
  :
  flit install --python ${TOOLCHAIN}/bin/python3
  #flit install [--symlink] [--python path/to/python]
  #exec_thread_safe pip install --prefix=${TOOLCHAIN}
  #cp -pr build.LibreELEC-Generic.x86_64-12.0-devel/build/packaging-23.2/src/packaging build.LibreELEC-Generic.x86_64-12.0-devel/toolchain/lib/python3.11/site-packages
}
