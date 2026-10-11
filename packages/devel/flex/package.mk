# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="flex"
PKG_VERSION="2.6.4"
PKG_SHA256="e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995"
PKG_LICENSE="BSD-3-Clause"
PKG_SITE="https://github.com/westes/flex"
PKG_URL="https://github.com/westes/flex/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host m4:host autotools:host bison:host"
PKG_DEPENDS_TARGET="toolchain flex:host"
PKG_LONGDESC="A tool for generating programs that perform pattern-matching on text."
PKG_TOOLCHAIN="autotools"

# the prebuilt flex:host published as flex-reusable. flex looks for m4 in the
# PATH before the path it was configured with, so it needs no relocation
if reusable_host_tool; then
  PKG_DEPENDS_HOST="flex-reusable:host"
fi

PKG_CONFIGURE_OPTS_HOST="--enable-static --disable-shared --disable-rpath --with-gnu-ld"

PKG_CONFIGURE_OPTS_TARGET="--disable-bootstrap \
                           ac_cv_func_realloc_0_nonnull=yes \
                           ac_cv_func_malloc_0_nonnull=yes"

pre_configure_host() {
  # flex needs nothing from the toolchain, leave its path out of a reusable flex
  if listcontains "${BUILD_REUSABLE}" "(all|flex:host)"; then
    LDFLAGS="${LDFLAGS/-Wl,-rpath,${TOOLCHAIN}\/lib/}"
  fi
}

post_makeinstall_host() {
  cat >${TOOLCHAIN}/bin/lex  <<"EOF"
#!/bin/sh
exec flex "$@"
EOF

  chmod -v 755 ${TOOLCHAIN}/bin/lex

  if listcontains "${BUILD_REUSABLE}" "(all|flex:host)"; then
    local dir="${PKG_BUILD}/.reusable/flex-reusable-${PKG_REUSABLE_VERSION}"
    reusable_stage_install "${dir}"
    cp -a ${TOOLCHAIN}/bin/lex "${dir}/bin"
    reusable_save "${dir}"
  fi
}
