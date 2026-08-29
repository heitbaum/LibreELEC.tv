#!/bin/bash
# rootfs/ + a kernel  ->  out/boot.img
#
# The rk1808 has no storage - maskrom downloads this into RAM every power
# cycle - so a bad image cannot brick anything. It just fails to boot and a
# power cycle returns the die to maskrom.
set -e
cd "$(dirname "$0")/.."

KERNEL="${KERNEL:-kernel/arch/arm64/boot/Image}"
OUT="${OUT:-out/boot.img}"
mkdir -p out build

echo "=== kernel ==="
if [ -f "$KERNEL" ]; then
  cp "$KERNEL" build/kernel
  echo "  $KERNEL  $(stat -c %s build/kernel) bytes"
else
  cp unpacked/kernel build/kernel
  echo "  (stock kernel)  $(stat -c %s build/kernel) bytes"
fi

# ROOTFS picks which tree to pack - the 2019 one we unpacked, or the 2022 one
# from airockchip/RK3399Pro_npu with its newer rknn_server.
ROOTFS="${ROOTFS:-rootfs}"
echo "=== ramdisk from $ROOTFS ==="
[ -d "$ROOTFS" ] || { echo "  no such rootfs: $ROOTFS" >&2; exit 1; }
( cd "$ROOTFS" && find . | LC_ALL=C sort | cpio -o -H newc --quiet ) | gzip -9 > build/ramdisk
echo "  $(find "$ROOTFS" | wc -l) entries -> $(stat -c %s build/ramdisk) bytes"

# The second area is a rockchip resource image, not a bare dtb, so swapping the
# device tree means unpacking it, replacing rk-kernel.dtb and repacking. Set
# DTB to a compiled dtb to do that; leave it unset for the stock one.
#
#   DTB=kernel/arch/arm64/boot/dts/rockchip/rk3399pro-npu-evb-v10.dtb #     bash tools/build.sh
DTB="${DTB:-}"
if [ -n "$DTB" ]; then
  echo "=== dtb (substituted) ==="
  [ -f "$DTB" ] || { echo "  no such dtb: $DTB" >&2; exit 1; }
  rm -rf build/resource
  cp -a unpacked/resource build/resource
  cp "$DTB" build/resource/rk-kernel.dtb
  python3 tools/resource.py repack build/resource build/second >/dev/null
  echo "  $DTB  ($(stat -c %s "$DTB") bytes) -> resource $(stat -c %s build/second) bytes"
else
  echo "=== dtb (stock - known good for this board) ==="
  cp unpacked/second build/second
  echo "  $(stat -c %s build/second) bytes"
fi
cp unpacked/manifest.json build/manifest.json

echo "=== pack ==="
python3 tools/bootimg.py repack build "$OUT"
