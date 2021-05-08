# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="cargo"
PKG_VERSION="0.53.0"
#PKG_SHA256="127be796380ddbd979679f97c01e1e61e4b6d91f1a28560995a7a543bc568f21"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://doc.rust-lang.org/stable/cargo/"
PKG_URL="https://github.com/rust-lang/cargo/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="The Rust package manager"
PKG_TOOLCHAIN="manual"

make_target() {
  . $(get_build_dir rust)/cargo/env
  cargo build --verbose --release
}
