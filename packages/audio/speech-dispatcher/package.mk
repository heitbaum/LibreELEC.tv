PKG_NAME="speech-dispatcher"
PKG_VERSION="0.11.4"
PKG_SHA256="8c09221bb72d9db5c89cfd7b919771832b86c3a3772d645601696494edf566b9"
PKG_LICENSE="LGPL"
PKG_SITE="https://freebsoft.org/speechd"
PKG_URL="https://github.com/brailcom/speechd/releases/download/$PKG_VERSION/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain dotconf glib libsndfile libpthread-stubs alsa-lib pulseaudio"
PKG_LONGDESC="Common high-level interface to SS"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="ac_cv_func_realloc_0_nonnull=yes \
                           ac_cv_func_malloc_0_nonnull=yes"

pre_configure_target()
{
  export MAKEINFO=true
}

post_unpack() {
  find "${PKG_BUILD}" -name "*" -type f -exec \
    sed -i 's:g_strdup_printf("%s/../libexec/speech-dispatcher-modules", user_data_dir);:g_strdup_printf("%s/modules", SpeechdOptions.runtime_speechd_dir);:g' {} \;
}

post_makeinstall_target() {
  cp -a $PKG_DIR/locale $INSTALL/usr/lib/
}
