# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2023-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="flit"
PKG_VERSION="3.9.0"
PKG_SHA256="55e28d0953726c4c744f02779b85f733f65da5bffb6a5d2fe11072d19ca2d148"
PKG_LICENSE="BSD 3-Clause"
PKG_SITE="https://flit.pypa.io"
PKG_URL="https://files.pythonhosted.org/packages/b1/a6/e9227cbb501aee4fa4a52517d3868214036a7b085d96bd1e4bbfc67ad6c6/flit-${PKG_VERSION}.tar.gz"
PKG_URL="https://github.com/pypa/flit/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="Python3:host docutils:host requests:host"
PKG_LONGDESC="Simplified packaging of Python modules"
PKG_TOOLCHAIN="manual"

make_host() {
  export DONT_BUILD_LEGACY_PYC=1
  #exec_thread_safe python -m flit_core.wheel
}

makeinstall_host() {
  # pip install docutils requests
  export DONT_BUILD_LEGACY_PYC=1
  #exec_thread_safe python bootstrap_install.py dist/flit_core-*.whl --prefix=${TOOLCHAIN}
  ${TOOLCHAIN}/bin/python -m ensurepip --altinstall
  exec_thread_safe python bootstrap_dev.py
  #exec_thread_safe python bootstrap_dev.py dist/flit_core-*.whl
  #exec_thread_safe python bootstrap_install.py dist/flit_core-*.whl
  python -m flit install --symlink
}
