# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2025-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mesa-host"
PKG_VERSION="${OS_VERSION}-$(get_pkg_version mesa)"
PKG_SHA256=""
PKG_LICENSE="OSS"
PKG_SITE="http://www.mesa3d.org/"
PKG_URL=""
PKG_DEPENDS_HOST="toolchain:host"
PKG_LONGDESC="Mesa is a 3-D graphics library with an API."
PKG_TOOLCHAIN="manual"

PKG_SOURCE_NAME="${PKG_NAME}-${PKG_VERSION}-${MACHINE_HARDWARE_NAME}.tar"
PACKAGE="${SOURCES}/${PKG_NAME}/${PKG_SOURCE_NAME}"

_get_file_already_downloaded() {
  [ ! -f "${PACKAGE}" -o ! -f "${STAMP_URL}" -o ! -f "${STAMP_SHA}" ] && return 1
  CALC_SHA256=$(sha256sum "${PACKAGE}" | cut -d" " -f1)
  [ -n "${CALC_SHA256}" -a "$(cat ${STAMP_SHA} 2>/dev/null)" != "${CALC_SHA256}" ] && return 1
  return 0
}

pre_unpack() {
  # todo - check gh for release before attempting download
  PKG_URL="https://github.com/heitbaum/mesa-host/releases/download/${PKG_VERSION}/${PKG_SOURCE_NAME}"
  STAMP_URL="${PACKAGE}.url"
  STAMP_SHA="${PACKAGE}.sha256"

  # Latest file already present, skipping download...
  if ! _get_file_already_downloaded; then

    mkdir -p "${SOURCES}/${PKG_NAME}"

    GET_CMD="curl --fail --connect-timeout 30 --retry 3 --continue-at - --location --max-redirs 5 --output ${PACKAGE}"
    rm -f "${STAMP_URL}" "${STAMP_SHA}" "${PACKAGE}"
    if ${GET_CMD} "${PKG_URL}"; then
      # package downloaded successfully
      # downloading sha256
      if ${GET_CMD}.sha256 "${PKG_URL}.sha256"; then
        # package sha256 downloaded successfully
        echo ${PKG_URL} > ${STAMP_URL}
        CALC_SHA256=$(sha256sum "${PACKAGE}" | cut -d" " -f1)
        if [ -n "${CALC_SHA256}" -a "$(cat ${STAMP_SHA} 2>/dev/null)" != "${CALC_SHA256}" ]; then
          build_msg "CLR_WARNING" "WARNING" "Incorrect checksum calculated on downloaded file: got ${CALC_SHA256} wanted $(cat ${STAMP_SHA} 2>/dev/null)"
          rm -f "${STAMP_URL}" "${STAMP_SHA}" "${PACKAGE}"
        fi
      else
        # package sha256 missing
        rm -f "${STAMP_URL}" "${STAMP_SHA}" "${PACKAGE}"
      fi
    else
      # package missing
      build_msg "CLR_WARNING" "WARNING" "mesa host tools unavailable for download"
      rm -f "${STAMP_URL}" "${STAMP_SHA}" "${PACKAGE}"
    fi
  fi
}

unpack() {
  if _get_file_already_downloaded; then
    build_msg "CLR_UNPACK" "UNPACK" "mesa host tools found, extracting mesa host tools"
    mkdir -p ${TOOLCHAIN}/bin
    tar -xf ${PACKAGE} -C ${TOOLCHAIN}/bin
  else
    build_msg "CLR_UNPACK" "WARNING" "mesa host tools was not found, failing back to build"
    # todo - if get/unpack,fails then call mesa:host to do the build
  fi
}
