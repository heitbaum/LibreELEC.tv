#!/bin/bash
# vendor boot.img  ->  unpacked/ (kernel, ramdisk, second, manifest) + rootfs/
#
# rootfs/ is the tree the build edits; unpacked/ is kept untouched so build.sh
# can reuse the stock dtb and so a round trip can be checked byte for byte.
set -e
cd "$(dirname "$0")/.."

IMG="${IMG:-boot.img}"
[ -f "$IMG" ] || { echo "no $IMG - fetch the vendor image first" >&2; exit 1; }

echo "=== unpack $IMG ==="
rm -rf unpacked
python3 tools/bootimg.py unpack "$IMG" unpacked

echo "=== round trip check ==="
python3 tools/bootimg.py repack unpacked build/.roundtrip.img >/dev/null
if cmp -s "$IMG" build/.roundtrip.img; then
  echo "  repack is byte identical to $IMG"
else
  echo "  WARNING: repack differs from $IMG - the header is not fully modelled" >&2
fi
rm -f build/.roundtrip.img

echo "=== rootfs from ramdisk ==="
rm -rf rootfs && mkdir rootfs
# the ramdisk is gzipped cpio newc; keep ownership and device nodes
gzip -dc unpacked/ramdisk | ( cd rootfs && cpio -idm --quiet )
echo "  $(find rootfs | wc -l) entries"
