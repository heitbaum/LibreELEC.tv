# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="meson-firmware"
PKG_VERSION="548ecf585074a3b2aa1a380fdfba34cdc2b2b41d"
PKG_SHA256="0f47475ade7c966054ec0afe4810994c7c5dce36512ace3caff327933ed9622b"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/LibreELEC/meson-firmware"
PKG_URL="https://github.com/LibreELEC/meson-firmware/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="meson-firmware: Amlogic microcode firmware for the V4L2 mem2mem vdec driver"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  FW_TARGET_DIR=$INSTALL/$(get_full_firmware_dir)

  if find_file_path config/$PKG_NAME.dat; then
    FW_LISTS="${FOUND_PATH}"
  else
    FW_LISTS="${PKG_DIR}/firmwares/any.dat ${PKG_DIR}/firmwares/${TARGET_ARCH}.dat"
  fi

  for fwlist in ${FW_LISTS}; do
    [ -f ${fwlist} ] || continue
    while read -r fwline; do
      [ -z "${fwline}" ] && continue
      [[ ${fwline} =~ ^#.* ]] && continue
      [[ ${fwline} =~ ^[[:space:]] ]] && continue

      for fwfile in $(cd ${PKG_BUILD} && eval "find ${fwline}"); do
        [ -d ${PKG_BUILD}/${fwfile} ] && continue

        if [ -f ${PKG_BUILD}/${fwfile} ]; then
          mkdir -p $(dirname ${FW_TARGET_DIR}/${fwfile})
            cp -Lv ${PKG_BUILD}/${fwfile} ${FW_TARGET_DIR}/${fwfile}
        else
          echo "ERROR: Firmware file ${fwfile} does not exist - aborting"
          exit 1
        fi
      done
    done < ${fwlist}
  done
}
