# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="hatch"
PKG_VERSION="1.15.0"
PKG_SHA256="714c1942253f02669d3c6ca78967b8e11f49498a8bf1e52a515c1e232d755203"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/pypa/hatch"
PKG_URL="https://github.com/pypa/hatch/archive/refs/tags/hatch-v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="hatchling:host hatch-vcs:host setuptools-scm:host"
PKG_LONGDESC="Modern, extensible Python project management"
PKG_TOOLCHAIN="python"

xPKG_CMAKE_OPTS_HOST="-DPYBIND11_TEST=OFF -DPYBIND11_INSTALL=ON -DUSE_PYTHON_INCLUDE_DIR=ON"
xPKG_CMAKE_OPTS_TARGET="-DPYBIND11_TEST=OFF -DPYBIND11_USE_CROSSCOMPILING=ON -DPYBIND11_INSTALL=ON -DUSE_PYTHON_INCLUDE_DIR=ON"

pre_configure_target() {
  cd ../backend
  rm -rf .${TARGET_NAME}
}
