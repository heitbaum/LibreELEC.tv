# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="ccache-reusable"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://ccache.dev/download.html"
PKG_DEPENDS_HOST="zstd:host libfmt:host xxHash:host"
PKG_LONGDESC="Prebuilt ccache:host."

reusable_archive_package ccache

post_makeinstall_host() {
  setup_ccache_host
}
