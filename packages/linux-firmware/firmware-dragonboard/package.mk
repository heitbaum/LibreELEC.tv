# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="firmware-dragonboard"
PKG_VERSION="1.4.0"
PKG_SHA256="822d2f8506d9657dbce6aa2bfce81ccbf97dcfc40831b70703b14b3f296fa4c0"
PKG_ARCH="aarch64 arm"
PKG_LICENSE="proprietary"
PKG_SITE="https://developer.qualcomm.com/"
PKG_URL="https://developer.qualcomm.com/download/db410c/firmware-410c-${PKG_VERSION}.bin"
PKG_DEPENDS_TARGET="toolchain mtools:host"
PKG_LONGDESC="Additional firmware for Dragonboard 410c"
PKG_TOOLCHAIN="manual"
# https://developer.qualcomm.com/qfile/67733/dragonboard_410c.zip.1.0-r1036.1.zip
# https://developer.qualcomm.com/qfile/35475/linux-board-support-package-r1034.2.1.zip
# https://developer.qualcomm.com/qfile/34896/linux-board-support-package-r1032.1.1.zip
# https://developer.qualcomm.com/qfile/34250/linux-board-support-package-r1032.1.zip
# https://developer.qualcomm.com/qfile/33505/linux-bootloader-and-firmware-v1030.4-psci.zip
# https://developer.qualcomm.com/qfile/33428/linux-board-support-package-v1.4.zip
#

unpack() {
  mkdir -p ${PKG_BUILD}
    cd ${PKG_BUILD}
    sh ${SOURCES}/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.bin --auto-accept
}

make_target() {
  :
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_firmware_dir)/qcom/venus-1.8/
    cp -a linux-board-support-package-v${PKG_VERSION%.0}/proprietary-linux/* ${INSTALL}/$(get_full_firmware_dir)
    cp -a linux-board-support-package-v${PKG_VERSION%.0}/proprietary-linux/venus* ${INSTALL}/$(get_full_firmware_dir)/qcom/venus-1.8/
    rm ${INSTALL}/$(get_full_firmware_dir)/firmware.tar

    MTOOLS_SKIP_CHECK=1 mcopy -n -i linux-board-support-package-v${PKG_VERSION%.0}/bootloaders-linux/NON-HLOS.bin \
                                    ::image/modem.* \
                                    ::image/mba.mbn \
                                    ::image/wcnss.* \
                                    ${INSTALL}/$(get_full_firmware_dir)
}
