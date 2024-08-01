# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="bottom"
PKG_VERSION="0.10.1"
PKG_SHA256="c0e507cc3a5246e65521e91391410efc605840abe3b40194c5769265051fa1cc"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/ClementTsang/bottom"
PKG_URL="https://github.com/ClementTsang/bottom/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain cargo:host"
PKG_LONGDESC="A TUI system monitor written in Rust."
PKG_TOOLCHAIN="manual"

make_target() {
  cargo build \
    --target ${TARGET_NAME} \
    --release \
    --locked \
    --all-features
}

makeinstall_target() {
  mkdir -p ${INSTALL}
  cp ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/btm ${INSTALL}
}
