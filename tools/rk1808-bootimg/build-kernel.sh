#!/bin/bash
# Build the rk1808 kernel with the usb network gadget enabled.
#
# The shipped kernel is a trimmed build that accepts no gadget function except
# FunctionFS, so there is no way to add a network interface without rebuilding.
# The vendor defconfig already carries CONFIG_USB_CONFIGFS_RNDIS=y.
set -e
set -o pipefail
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC="aarch64-linux-gnu-gcc-11"
J=$(nproc)

cd "$(dirname "$0")/../kernel"
make rk1808_linux_defconfig

# the gadget functions we need on top of the defconfig. Only rndis is used:
# ncm builds and binds but oopses composite_setup when it shares a config with
# ffs.ntb, and it never completes enumeration even on its own. ncm and ecm are
# left enabled so that is cheap to retest on a newer kernel.
./scripts/config --enable CONFIG_USB_CONFIGFS_RNDIS
./scripts/config --enable CONFIG_USB_CONFIGFS_NCM
./scripts/config --enable CONFIG_USB_CONFIGFS_ECM

# the vendor kernel carries no CONFIG_IKCONFIG, which is why their .config
# cannot be recovered from the shipped image. Do not repeat that.
./scripts/config --enable CONFIG_IKCONFIG
./scripts/config --enable CONFIG_IKCONFIG_PROC

# rk1808_linux_defconfig is not what rockchip shipped - theirs is trimmed hard
# (no network stack at all) and a third of the size. It has to cover every
# rk1808 product they make; we build for one of them, in its most cut down
# role, so most of it is dead weight.
#
# Everything here is absent from the vendor image's /sys/class and /sys/bus,
# which is the evidence it is safe: rockchip run this same silicon without it.
#
# The die's gmac is real silicon - rk1808.dtsi has ethernet@ffdd0000 - but it
# is status = "disabled" there and no board dts enables it, so stmmac is dead
# weight. The usbnet drivers are the host side of USB ethernet, for a dongle
# plugged into the die; the gadget side we do use is USB_CONFIGFS_RNDIS and is
# a different subsystem. Between them they were what kept PHYLIB on, and PHYLIB
# drags in PTP_1588_CLOCK and PPS.
#
# Kept, because galcore imports it or rndis needs it: NET, NETDEVICES,
# USB gadget, IOMMU, DEVFREQ + DEVFREQ_THERMAL, REGULATOR, DMA_SHARED_BUFFER,
# THERMAL, I2C, CLK.
#
# PCI stays, and not because the die uses it. CONFIG_PCI_MSI selects
# GENERIC_MSI_IRQ, which guards msi_list *inside struct device*. Drop PCI and
# the struct shrinks, every field after it shifts, and the prebuilt galcore -
# compiled against a kernel that had it - reads dev->of_node from the wrong
# offset and dies:
#
#   Unable to handle kernel paging request at virtual address 00080040
#   PC is at __of_find_property+0x18/0x60
#   ... gpu_init+0x70/0x1000 [galcore]
#
# Nothing else in this tree can select GENERIC_MSI_IRQ: the only other path is
# ARM_SMMU_V3, which itself depends on PCI. So a binary-only galcore puts a
# hard floor under how far the config can be trimmed - the limit is struct
# layout, not which symbols are exported. That leaves pci_bus in /sys/class
# and pci/pci_express in /sys/bus, which the vendor image does not have.
#
# The second group is drivers for IP the shipped dtb leaves disabled, so they
# can never bind: rk_rga@ffaf0000, vpu_service@ffb80000, mipi-dphy@ff370000 and
# pcie@fc400000 are all status = "disabled" there. The pcie port services go
# with them - PCI_MSI stays, it is the reason PCI is here at all.
#
# The third group cuts NET back to what the shell actually needs - NET, INET
# and NETDEVICES - and drops the disk filesystems. The die mounts rootfs,
# devtmpfs, proc, devpts, sysfs, debugfs, configfs, functionfs and three
# tmpfs, and nothing else ever; it has no storage. ext4, vfat, ntfs and
# squashfs are all dead weight.
#
# The vendor kernel was built CONFIG_NET=n outright and every bit of the die's
# own software still ran, so nothing here needs AF_PACKET or ipv6 - only our
# own ifconfig/inetd/nc path needs INET.
#
# AF_UNIX is kept even though nothing strictly needs it: without it udev loses
# its control socket and complains on every boot, and the few kb are not worth
# a permanent error in the log.
#
# CRYPTO cannot go: net/Kconfig:60 has INET select it, so /proc/crypto stays
# for as long as we want tcp. Dropping ext4 removes the other selector.
#
# One per line, no backslash continuations - a line continuation here does not
# survive a crlf round trip, and the result stays valid shell, so the list
# silently shrinks instead of failing.
DISABLE="
CONFIG_BT
CONFIG_RC_CORE
CONFIG_MEDIA_SUPPORT
CONFIG_SOUND
CONFIG_SND
CONFIG_DRM
CONFIG_FB
CONFIG_VT
CONFIG_BACKLIGHT_LCD_SUPPORT
CONFIG_BACKLIGHT_CLASS_DEVICE
CONFIG_SCSI
CONFIG_MMC
CONFIG_WLAN
CONFIG_WL_ROCKCHIP
CONFIG_CFG80211
CONFIG_MAC80211
CONFIG_RFKILL
CONFIG_STMMAC_ETH
CONFIG_STMMAC_PLATFORM
CONFIG_DWMAC_ROCKCHIP
CONFIG_USB_NET_DRIVERS
CONFIG_USB_USBNET
CONFIG_PHYLIB
CONFIG_SPI
CONFIG_IIO
CONFIG_RTC_CLASS
CONFIG_NEW_LEDS
CONFIG_PPS
CONFIG_PTP_1588_CLOCK
CONFIG_PWM
CONFIG_I2C_CHARDEV
CONFIG_ROCKCHIP_RGA2
CONFIG_RK_VCODEC
CONFIG_PHY_ROCKCHIP_INNO_MIPI_DPHY
CONFIG_PCIEPORTBUS
CONFIG_PCIEAER
CONFIG_PCIEASPM
CONFIG_PCIE_PME
CONFIG_IPV6
CONFIG_BRIDGE
CONFIG_XFRM
CONFIG_NET_KEY
CONFIG_WIRELESS
CONFIG_PACKET
CONFIG_NETFILTER
CONFIG_EXT4_FS
CONFIG_JBD2
CONFIG_FAT_FS
CONFIG_VFAT_FS
CONFIG_NTFS_FS
CONFIG_SQUASHFS
"
for opt in $DISABLE; do
  ./scripts/config --disable "$opt"
done

# DRM selects DMA_SHARED_BUFFER, so dropping DRM takes dma_buf with it - and
# galcore imports dma_buf_get/attach/map_attachment, as do rockchip's rga2 and
# vcodec drivers, so the link fails without it.
#
# DMA_SHARED_BUFFER has no prompt of its own and olddefconfig clears anything
# nothing selects, so it cannot just be switched on. SYNC is the smallest
# visible symbol that selects it - a framework with no /sys/class of its own,
# unlike ION which would also drag in the allocator and /dev/ion.
./scripts/config --enable CONFIG_SYNC

make olddefconfig

echo "--- gadget functions in .config ---"
grep -E "USB_CONFIGFS_(RNDIS|NCM|ECM|F_FS)" .config | sed 's/^/  /'

echo "--- anything that survived the trim (a dependency forced it back on) ---"
survivors=0
for opt in $DISABLE; do
  if grep -qE "^${opt}=" .config; then
    echo "  STILL SET: $(grep -E "^${opt}=" .config)"
    survivors=$((survivors + 1))
  fi
done
[ "$survivors" -eq 0 ] && echo "  none - the whole list is off"

echo "--- must still be present ---"
KEEP="CONFIG_NET CONFIG_NETDEVICES CONFIG_USB_CONFIGFS CONFIG_DMA_SHARED_BUFFER
CONFIG_PM_DEVFREQ CONFIG_DEVFREQ_THERMAL CONFIG_REGULATOR CONFIG_IOMMU_SUPPORT
CONFIG_I2C CONFIG_IKCONFIG_PROC CONFIG_PCI_MSI CONFIG_GENERIC_MSI_IRQ CONFIG_UNIX"
for opt in $KEEP; do
  grep -qE "^${opt}=y" .config && echo "  ok   $opt" || echo "  LOST $opt"
done

# arch/arm64/Makefile passes -fno-asynchronous-unwind-tables, which was enough
# for the gcc 6.3 this tree was written for. gcc 11 also needs -fno-unwind-tables,
# and 4.4's DISCARDS does not drop .eh_frame either, so without this the image
# carries a megabyte of unwind tables that nothing in the kernel ever reads.
echo "--- building Image with $(${CC} --version | head -1) ---"
make -j"$J" CC="${CC}" KCFLAGS="-fno-unwind-tables" Image 2>&1 | tail -25
ls -l arch/arm64/boot/Image
echo "--- .eh_frame (want a few bytes, not a megabyte) ---"
aarch64-linux-gnu-readelf -S -W vmlinux 2>/dev/null | grep eh_frame | sed 's/^/  /'
