# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="cmake"
PKG_VERSION="4.4.4"
PKG_SHA256="bd24c30d80a7744ae84b845ff080cc8453b06c622ef01066564108e9cefc44cf"
PKG_LICENSE="BSD-3-Clause"
PKG_SITE="https://cmake.org/"
PKG_URL="https://cmake.org/files/v$(get_pkg_version_maj_min)/cmake-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="pkg-config:host"
PKG_LONGDESC="A cross-platform, open-source make system."
PKG_TOOLCHAIN="configure"
PKG_BUILD_FLAGS="+local-cc"

# the prebuilt cmake:host published as cmake-reusable, named after a hash of
# the recipe so that a stale archive is never used
if [ "${USE_REUSABLE}" = "yes" -o "${USE_REUSABLE}" = "preferred" ] ||
   listcontains "${BUILD_REUSABLE}" "(all|cmake:host)"; then
  PKG_REUSABLE_HASH="$(get_reusable_inputs_hash cmake)"
  PKG_REUSABLE_VERSION="${OS_VERSION}-${PKG_VERSION}"
  PKG_REUSABLE_SOURCE_NAME="cmake-reusable-${PKG_REUSABLE_VERSION}-${MACHINE_HARDWARE_NAME}-${PKG_REUSABLE_HASH}.tar.xz"
  PKG_REUSABLE_URL="${REUSABLE_URL}/cmake-${PKG_REUSABLE_VERSION}/${PKG_REUSABLE_SOURCE_NAME}"
fi

# preferred falls back to building cmake:host when no reusable archive is available
if [ "${USE_REUSABLE}" = "yes" ] ||
   { [ "${USE_REUSABLE}" = "preferred" ] &&
     [ -n "$(get_reusable_sha256 cmake-reusable ${PKG_REUSABLE_SOURCE_NAME} ${PKG_REUSABLE_URL})" ]; }; then
  # cmake then only pulls in the archive
  PKG_REUSABLE="yes"
  PKG_SECTION="virtual"
  PKG_URL=""
  PKG_SHA256=""
  PKG_DEPENDS_HOST="pkg-config:host cmake-reusable:host"
  # scripts/build still unpacks a virtual package, and there is no source to patch
  PKG_SKIP_PATCHES="yes"
fi

configure_host() {
  local ldflags="${HOST_LDFLAGS}"

  # cmake needs nothing from the toolchain, so leave its path out of a
  # reusable cmake and the archive can be unpacked into any toolchain
  if listcontains "${BUILD_REUSABLE}" "(all|cmake:host)"; then
    ldflags="${ldflags/-Wl,-rpath,${TOOLCHAIN}\/lib/}"
  fi

  ../configure --prefix=${TOOLCHAIN} \
               --no-qt-gui --no-system-libs \
               -- \
               -DCMAKE_C_FLAGS="-O2 -Wall -pipe -Wno-format-security" \
               -DCMAKE_CXX_FLAGS="-O2 -Wall -pipe -Wno-format-security" \
               -DCMAKE_EXE_LINKER_FLAGS="${ldflags}" \
               -DCMAKE_USE_OPENSSL=OFF \
               -DBUILD_CursesDialog=0
}

post_makeinstall_host() {
  if listcontains "${BUILD_REUSABLE}" "(all|cmake:host)"; then
    save_cmake_reusable
  fi
}

# pack cmake:host as the cmake-reusable archive
save_cmake_reusable() {
  local stage="${PKG_BUILD}/.reusable/stage"
  local dir="${PKG_BUILD}/.reusable/cmake-reusable-${PKG_REUSABLE_VERSION}"

  rm -rf "${PKG_BUILD}/.reusable"
  make install DESTDIR="${stage}"
  mv "${stage}${TOOLCHAIN}" "${dir}"
  rm -rf "${stage}" "${dir}/doc"

  # a reusable cmake must not name the toolchain it was built in
  if grep -rlaF "${TOOLCHAIN}" "${dir}"; then
    die "cmake-reusable names ${TOOLCHAIN} and cannot be unpacked into another toolchain"
  fi

  {
    echo "archive: ${PKG_REUSABLE_SOURCE_NAME}"
    echo "host: ${MACHINE_HARDWARE_NAME}"
    echo "cmake: ${PKG_VERSION}"
  } >"${dir}/MANIFEST"

  save_reusable cmake-reusable "${PKG_REUSABLE_SOURCE_NAME}" "${dir}"
}
