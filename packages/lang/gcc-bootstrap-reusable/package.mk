# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gcc-bootstrap-reusable"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://gcc.gnu.org/"
PKG_DEPENDS_HOST="ccache:host zstd:host"
PKG_LONGDESC="Prebuilt gcc:bootstrap for the target."

reusable_archive_package gcc

post_makeinstall_host() {
  setup_gcc_bootstrap
}
