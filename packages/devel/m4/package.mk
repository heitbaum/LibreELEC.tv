# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="m4"
PKG_VERSION="1.4.21"
PKG_SHA256="dc487e11d2f0c9e01555bb1af26be4eae983ec8f0726746505b4327186eb21fc"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="http://www.gnu.org/software/m4/"
PKG_URL="https://ftpmirror.gnu.org/m4/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_HOST="ccache:host"
PKG_LONGDESC="The m4 macro processor."
PKG_BUILD_FLAGS="-cfg-libs:host"

# the prebuilt m4:host published as m4-reusable
if reusable_host_tool; then
  PKG_DEPENDS_HOST="m4-reusable:host"
fi

PKG_CONFIGURE_OPTS_HOST="gl_cv_func_gettimeofday_clobber=no --target=${TARGET_NAME}"

pre_configure_host() {
  # m4 needs nothing from the toolchain, leave its path out of a reusable m4
  if listcontains "${BUILD_REUSABLE}" "(all|m4:host)"; then
    LDFLAGS="${LDFLAGS/-Wl,-rpath,${TOOLCHAIN}\/lib/}"
  fi
}

post_makeinstall_host() {
  # before the install into the sysroot, which changes the prefix
  if listcontains "${BUILD_REUSABLE}" "(all|m4:host)"; then
    reusable_save_install
  fi

  make prefix=${SYSROOT_PREFIX}/usr install
}
