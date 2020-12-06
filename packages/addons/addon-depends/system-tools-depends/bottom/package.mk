# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="bottom"
PKG_VERSION="0.5.3"
PKG_SHA256="5a22e60518f0875e25e36fc420ebd5d9b354bd9994201aed36694c7b620ff243"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/ClementTsang/bottom"
PKG_URL="https://github.com/ClementTsang/bottom/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain rust"
PKG_LONGDESC="A TUI system monitor written in Rust."
PKG_TOOLCHAIN="manual"

make_target() {
  . "$(get_build_dir rust)/cargo/env"
  cargo build \
    --release \
    --locked \
    --all-features
}

makeinstall_target() {
  mkdir -p $INSTALL
  cp $PKG_BUILD/.$TARGET_NAME/*/release/btm $INSTALL
}
