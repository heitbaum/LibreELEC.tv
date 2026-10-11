# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="bison"
PKG_VERSION="3.8.2"
PKG_SHA256="9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="http://www.gnu.org/software/bison/"
PKG_URL="https://ftpmirror.gnu.org/bison/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="ccache:host m4:host"
PKG_LONGDESC="A general-purpose parser generator."
PKG_BUILD_FLAGS="-parallel -cfg-libs:host"

PKG_CONFIGURE_OPTS_HOST="--disable-rpath --with-gnu-ld"

# the prebuilt bison:host published as bison-reusable
if reusable_host_tool; then
  PKG_DEPENDS_HOST="bison-reusable:host"
elif listcontains "${BUILD_REUSABLE}" "(all|bison:host)"; then
  # bison then finds m4 and its skeletons relative to where it is installed.
  # libtextstyle only colours the diagnostics and would tie the archive to
  # the gettext of the toolchain it is unpacked into, so leave it out.
  PKG_CONFIGURE_OPTS_HOST+=" --enable-relocatable ac_cv_libtextstyle=no"
fi

post_configure_host() {
  # The configure system causes Bison to be built without support for
  # internationalization of error messages if a bison program is not already in
  # ${PATH}. The following addition will correct this:
  echo '#define YYENABLE_NLS 1' >>lib/config.h
}

pre_configure_host() {
  # a reusable bison needs nothing from the toolchain, leave its path out
  if listcontains "${BUILD_REUSABLE}" "(all|bison:host)"; then
    LDFLAGS="${LDFLAGS/-Wl,-rpath,${TOOLCHAIN}\/lib/}"
  fi
}

post_makeinstall_host() {
  if listcontains "${BUILD_REUSABLE}" "(all|bison:host)"; then
    local dir="${PKG_BUILD}/.reusable/bison-reusable-${PKG_REUSABLE_VERSION}"
    reusable_stage_install "${dir}"
    # reusable_install fills the toolchain path into yacc, so turn off its own
    # relocation, which goes wrong when it is run from stdin
    [ "$(grep -c '^if test "yes" = yes; then$' "${dir}/bin/yacc")" = "1" ] ||
      die "yacc no longer has the relocation block that bison-reusable turns off"
    sed -i 's|^if test "yes" = yes; then$|if test "no" = yes; then|' "${dir}/bin/yacc"
    reusable_save "${dir}"
  fi
}
