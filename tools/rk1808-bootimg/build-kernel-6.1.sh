#!/bin/bash
# Build a 6.1 kernel for the die, as a step towards getting off the 4.4 tree.
#
# This is the cheap half of that move. Every piece of rk1808 soc support already
# exists on rockchip's develop-6.1 - clk-rk1808.c, the pinctrl data, the efuse
# and thermal tables, rk1808.dtsi - so nothing has to be forward ported. What is
# missing there is only the board description: no rk3399pro-npu file exists on
# any branch after develop-4.4.
#
# It turns out to port with no edits at all. The two files from the 4.4 tree,
#
#     rk3399pro-npu.dtsi           1393 lines, a parallel soc dtsi for the
#                                  rk1808-as-npu configuration
#     rk3399pro-npu-evb-v10.dts     200 lines, the board on top of it
#
# compile unchanged against 6.1: every dt-bindings header they include is
# present, and every label they reference resolves. Their bootargs are already
# right for this die - init=/init, no root=, console on ttyFIQ0, which the
# vendor 6.1 tree still has.
#
# The boot chain does not change either. u-boot, trust and the loader stay as
# they are, and build.sh packs the result into the same container.
#
# What this does NOT get you is the npu: galcore is built for 4.4 and will not
# load here. See the etnaviv section of the README for the only route to that.
set -e
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
K61="${K61:-$ROOT/../npu-research/kernel-6.1}"
K44="${K44:-$ROOT/kernel}"
D=arch/arm64/boot/dts/rockchip

[ -d "$K61" ] || cat <<EOF >&2
no 6.1 tree at $K61 - clone it with

  git clone --depth 1 --branch develop-6.1 \
      https://github.com/rockchip-linux/kernel.git $K61

EOF
[ -d "$K61" ] || exit 1

# 6.1 Kconfig checks \$(CROSS_COMPILE)gcc directly, so the unversioned cross
# compiler has to exist - run.sh installs it alongside the gcc-11 that 4.4 wants
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# Rockchip ship both board files on 6.1, 6.6 and 6.12, already adapted for those
# trees - 826 and 140 lines against 4.4's 1393 and 200 - and their versions drop
# the vdd_npu_1 regulator this board does not have and enable &combphy already.
# So prefer the tree's own, and only fall back to the 4.4 copies for a tree that
# genuinely lacks them. An earlier version of this script had it backwards and
# overwrote rockchip's with the 4.4 ones.
echo "=== board dts ==="
for f in rk3399pro-npu.dtsi rk3399pro-npu-evb-v10.dts; do
  if [ -f "$K61/$D/$f" ]; then
    echo "  $f: using the tree's own ($(wc -l < "$K61/$D/$f") lines)"
  elif [ -f "$K44/$D/$f" ]; then
    cp "$K44/$D/$f" "$K61/$D/$f"
    echo "  $f copied from the 4.4 tree - this tree has none"
  else
    echo "  $f not found in either tree" >&2; exit 1
  fi
done

echo "=== combphy driver ==="
# 6.1 kept the phy in the device tree and dropped the driver, so usb had to run
# at 480Mbps. This brings the driver back from develop-5.10 and gets 5Gbps.
bash "$ROOT/tools/combphy-6.1.sh" | sed 's/^/  /'

echo "=== board dts adjustments ==="
python3 "$ROOT/tools/dts-6.1.py" "$K61/$D/rk3399pro-npu-evb-v10.dts"

cd "$K61"
echo "=== defconfig ==="
make rk1808_linux_defconfig 2>&1 | tail -2

# the same two things we want on the 4.4 build: a config we can read back off
# the die, and a network gadget so there is a way in
./scripts/config --enable CONFIG_IKCONFIG
./scripts/config --enable CONFIG_IKCONFIG_PROC
./scripts/config --enable CONFIG_USB_CONFIGFS_RNDIS

# The npu transfer proxy identifies the die by the usb serial, which
# S50usbdevice copies out of /proc/cpuinfo, which is populated from the efuse
# by rockchip-cpuinfo. Without it every id is zero and the host reports
# devid = 0000000000000000 instead of the real one.
./scripts/config --enable CONFIG_ROCKCHIP_CPUINFO

# the combphy installed above - without it dwc3 has no usb3 phy and the gadget
# falls back to 480Mbps, which is a silent ten times slower rather than a
# failure, so it is checked below like the rest
./scripts/config --enable CONFIG_PHY_ROCKCHIP_INNO_COMBPHY

# rga2 does not build on the 6.12 bsp - rga2_mmu_info.c calls
# get_user_pages_remote() with the old seven argument signature. That is
# rockchip's bug, not ours, and this board has nothing to do with rga: the
# rga2 and vcodec nodes are status="disabled" in the dtb the die boots. Turn it
# off rather than carry a patch for a block we never use.
./scripts/config --disable CONFIG_ROCKCHIP_RGA2
./scripts/config --disable CONFIG_ROCKCHIP_RGA2_DEBUG_FS
./scripts/config --disable CONFIG_ROCKCHIP_RGA2_DEBUGGER
make olddefconfig 2>&1 | tail -2

for opt in CONFIG_IKCONFIG_PROC CONFIG_USB_CONFIGFS_RNDIS CONFIG_ROCKCHIP_CPUINFO            CONFIG_PHY_ROCKCHIP_INNO_COMBPHY; do
  grep -qE "^${opt}=y" .config && echo "  ok   $opt" || echo "  LOST $opt"
done

echo "=== build, with $(aarch64-linux-gnu-gcc --version | head -1) ==="
make -j"$(nproc)" Image 2>&1 | tail -12
ls -l arch/arm64/boot/Image | awk '{printf "  Image: %s bytes\n", $5}'

# not in the dts Makefile - no rk1808 board is - so ask for it by name
echo "=== dtb ==="
make rockchip/rk3399pro-npu-evb-v10.dtb rockchip/rk3399pro-npu-dbg.dtb 2>&1 | tail -4
for f in rk3399pro-npu-dbg rk3399pro-npu-evb-v10; do
  echo "  $f.dtb  $(stat -c %s "$D/$f.dtb") bytes"
done

cat <<EOF

To pack it:

  KERNEL=$K61/arch/arm64/boot/Image \
  DTB=$K61/$D/rk3399pro-npu-evb-v10.dtb \
  OUT=out/boot-6.1.img bash tools/build.sh

EOF
