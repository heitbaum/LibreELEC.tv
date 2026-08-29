#!/bin/bash
# Build galcore from source instead of using rockchip's blob.
#
# Rockchip never published their galcore tree - see GALCORE-SOURCE.md for the
# search behind that. What they did not publish is one platform file. The other
# 99% is public: ST and Amlogic both ship the same DDK, 6.4.6, as source, and
# our blob is 6.4.6.5 build 351518 against ST's 342038.
#
# That source builds against Linux 6.1 with three small changes and no kernel
# api porting at all:
#
#   1. #include <stdarg.h> -> <linux/stdarg.h>   5.15 stopped letting modules
#                                                pull the host header
#   2. three -Wno-error=                         gcc 15 promotes vendor style
#                                                complaints to errors, 9 sites
#   3. MODULE_IMPORT_NS(DMA_BUF)                 5.16 moved dma_buf_* into
#                                                their own symbol namespace
#
# What it does NOT yet do is drive this hardware. SOC_PLATFORM=default builds a
# module with no board glue. The rk platform file - clocks, resets, the power
# domain for rockchip,npu, the AXI SRAM wiring, the irq and the opp/devfreq
# hookup - is the piece that is missing, and the amlogic templates in the same
# tree are the closest analogue at 179 to 649 lines.
#
#   GALSRC=... KERNEL_DIR=... SOC_PLATFORM=default bash tools/build-galcore.sh
set -e
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GALSRC="${GALSRC:-$ROOT/../npu-research/gcnano/gcnano-driver-6.4.6}"
KERNEL_DIR="${KERNEL_DIR:-$ROOT/../npu-research/kernel-6.1}"
SOC_PLATFORM="${SOC_PLATFORM:-default}"

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

[ -d "$GALSRC" ] || cat <<EOF >&2
no galcore source at $GALSRC - fetch it with

  git clone --depth 1 -b gcnano-6.4.6-binaries \
      https://github.com/heitbaum/gcnano-binaries gcnano
  tar xf gcnano/gcnano-driver-6.4.6.tar.xz -C gcnano/

Despite the repository name ST publish the kernel driver as source; only the
userland is binary. Other DDK versions are on sibling branches - 6.4.19 knows
kernels up to 6.8 and 6.4.21 up to 6.12, but staying on 6.4.6 keeps the ioctl
layout matching the die's 6.4.6.5 userspace.
EOF
[ -d "$GALSRC" ] || exit 1
[ -d "$KERNEL_DIR" ] || { echo "no kernel tree at $KERNEL_DIR" >&2; exit 1; }

echo "=== source ==="
echo "  $GALSRC"
grep -hoE "gcvVERSION_(PATCH|BUILD) *[0-9]+" "$GALSRC/hal/kernel/inc/gc_hal_version.h" |
  tr '\n' ' ' | sed 's/^/  /'; echo
echo "  platforms available: $(ls "$GALSRC/hal/os/linux/kernel/platform/" | tr '\n' ' ')"
echo "  building for: $SOC_PLATFORM"

# our own platform glue, the piece rockchip never published
if [ -d "$ROOT/platform" ]; then
  for v in "$ROOT"/platform/*; do
    [ -d "$v" ] || continue
    dst="$GALSRC/hal/os/linux/kernel/platform/$(basename "$v")"
    mkdir -p "$dst"
    cp "$v"/* "$dst"/
    echo "  installed platform/$(basename "$v"): $(ls "$v" | tr '
' ' ')"
  done
fi

echo "=== compat fixes ==="
# 1. the kernel ships its own stdarg.h since 5.15
n=0
while read -r f; do
  sed -i 's|#include <stdarg.h>|#include <linux/stdarg.h>|' "$f"
  n=$((n + 1))
done < <(grep -rl '#include <stdarg.h>' "$GALSRC/hal/" 2>/dev/null || true)
echo "  stdarg.h -> linux/stdarg.h in $n files"

# 2. dma_buf_* got a symbol namespace in 5.16 and modpost refuses without it
drv="$GALSRC/hal/os/linux/kernel/gc_hal_kernel_driver.c"
if grep -q "MODULE_IMPORT_NS(DMA_BUF)" "$drv"; then
  echo "  MODULE_IMPORT_NS(DMA_BUF) already present"
else
  python3 - "$drv" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
a = "MODULE_IMPORT_NS(VFS_internal_I_am_really_a_filesystem_and_am_NOT_a_driver);"
assert s.count(a) == 1, "VFS import anchor"
open(p, "w").write(s.replace(a, a + """
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5,16,0)
/* dma_buf_* moved into their own symbol namespace in 5.16 */
MODULE_IMPORT_NS(DMA_BUF);
#endif""", 1))
PY
  echo "  MODULE_IMPORT_NS(DMA_BUF) added"
fi

# 3. the userspace refuses to run against a driver that does not report the
# build number it was shipped with. rknn_server does not say so - it segfaults,
# because vsi_nn_CreateContext returns NULL and librknn_runtime does not check
# it before filling in the device name:
#
#     #0 vnn_CreateRKNN   str w0, [x22, #40]   with x22 = 0
#     #1 BuildGraph
#     #2 RKNNRuntime::init
#
# No ioctl fails on the way there - the driver is never asked for anything it
# refuses - so this is a version check in userspace, not an ABI difference.
# Claiming 351518 makes the whole stack work, and the inference output is
# bit identical to the vendor driver's.
#
# This is a compatibility claim, not a real version: the code is ST's 342038.
# It is honest about what it does and it is confined to this one define.
VERSION_CLAIM="${VERSION_CLAIM:-351518}"
if [ -n "$VERSION_CLAIM" ]; then
  h="$GALSRC/hal/kernel/inc/gc_hal_version.h"
  cur=$(grep -oE "gcvVERSION_BUILD +[0-9]+" "$h" | grep -oE "[0-9]+$")
  if [ "$cur" != "$VERSION_CLAIM" ]; then
    sed -i "s/#define gcvVERSION_BUILD *[0-9]*/#define gcvVERSION_BUILD     $VERSION_CLAIM/" "$h"
    sed -i "s/#define gcvVERSION_STRING *\"[0-9.]*\"/#define gcvVERSION_STRING    \"6.4.6.5.$VERSION_CLAIM\"/" "$h"
    echo "  version: reporting build $VERSION_CLAIM (source is $cur)"
  else
    echo "  version: already reporting $VERSION_CLAIM"
  fi
fi

# 4. four real api changes between 6.1 and 6.12. Each is applied by detecting
#    the kernel tree rather than by version number, so this keeps working as the
#    base moves, and each is a no-op on a tree that has not made the change.
echo "=== kernel api fixes ==="

# class_create() lost its owner argument in 6.4.
if grep -q "class_create(struct module \*owner" "$KERNEL_DIR/include/linux/device/class.h" 2>/dev/null; then
  echo "  class_create still takes an owner"
else
  n=0
  while read -r f; do
    sed -i 's/class_create(THIS_MODULE, *\([^)]*\))/class_create(\1)/g' "$f"
    n=$((n + 1))
  done < <(grep -rl "class_create(THIS_MODULE" "$GALSRC/hal/" 2>/dev/null || true)
  echo "  class_create owner argument dropped in $n files"
fi

# platform_driver.remove returns void from 6.11.
if grep -q "void (\*remove)(struct platform_device \*)" "$KERNEL_DIR/include/linux/platform_device.h"; then
  drv="$GALSRC/hal/os/linux/kernel/gc_hal_kernel_driver.c"
  if grep -q "^static void gpu_remove" "$drv"; then
    echo "  gpu_remove already returns void"
  else
    sed -i 's/^static int gpu_remove(struct platform_device \*pdev)/static void gpu_remove(struct platform_device *pdev)/' "$drv"
    python3 - "$drv" <<'PY'
import sys

# The declaration sits inside an #if/#else pair for pre-3.8 kernels, so the
# body does not follow it directly and a regex over "signature then braces"
# does not match. Work on the line range instead: from the void declaration to
# the first closing brace in column zero.
p = sys.argv[1]
lines = open(p).read().splitlines(keepends=True)
start = next(i for i, l in enumerate(lines)
             if l.startswith("static void gpu_remove(struct platform_device"))
end = next(i for i in range(start, len(lines)) if lines[i].startswith("}"))
n = 0
for i in range(start, end):
    if lines[i].strip() == "return 0;":
        lines[i] = ""
        n += 1
assert n == 1, "expected one return 0; in gpu_remove, found %d" % n
open(p, "w").write("".join(lines))
PY
    echo "  gpu_remove converted to void"
  fi
else
  echo "  platform remove still returns int"
fi

# the rest are mm and dma-buf changes, applied from 6.4.21's own version
# guarded forms rather than invented here
# GALREF points at an extracted 6.4.21 tree, used as the reference for glue
# that upstream rewrote rather than tweaked. Without it those grafts are
# skipped and the build will fail on kernels past 6.5.
GALREF="${GALREF:-$ROOT/../npu-research/ddk/6.4.21/gcnano-driver-stm32mp}"
python3 "$ROOT/tools/galcore-modern.py" "$GALSRC" "$GALREF"

# no_llseek was removed in 6.12; the default is already no-seek for these fops.
if grep -q "no_llseek" "$KERNEL_DIR/include/linux/fs.h"; then
  echo "    no_llseek still defined"
else
  n=0
  while read -r f; do
    sed -i '/\.llseek[[:space:]]*=[[:space:]]*no_llseek,/d' "$f"
    n=$((n + 1))
  done < <(grep -rl "no_llseek" "$GALSRC/hal/" 2>/dev/null || true)
  echo "    no_llseek assignments removed in $n files"
fi

# the kernel tree needs module.lds and Module.symvers before an external
# module can be built or modpost can resolve anything
if [ ! -f "$KERNEL_DIR/scripts/module.lds" ] || [ ! -f "$KERNEL_DIR/Module.symvers" ]; then
  echo "=== preparing the kernel tree ==="
  make -C "$KERNEL_DIR" -j"$(nproc)" modules_prepare 2>&1 | tail -2
  make -C "$KERNEL_DIR" -j"$(nproc)" modules 2>&1 | tail -2
fi

echo "=== build ==="
cd "$GALSRC"
# 3. gcc 15 turns these vendor style complaints into errors
make -j"$(nproc)" \
  ARCH_TYPE=arm64 \
  KERNEL_DIR="$KERNEL_DIR" \
  CROSS_COMPILE="$CROSS_COMPILE" \
  SOC_PLATFORM="$SOC_PLATFORM" \
  AQROOT="$GALSRC" \
  KCFLAGS="-Wno-error=implicit-fallthrough -Wno-error=enum-int-mismatch -Wno-error=unused-variable -Wno-error=missing-prototypes -Wno-error=missing-declarations -Wno-error=extra" \
  2>&1 | grep -E "error:|ERROR|Error [0-9]|LD \[M\]" | head -15

ko="$GALSRC/galcore.ko"
[ -f "$ko" ] || { echo "  no module produced" >&2; exit 1; }
echo "=== result ==="
echo "  $ko  $(stat -c %s "$ko") bytes"
aarch64-linux-gnu-strings "$ko" | grep -m1 "^vermagic" | sed 's/^/  /'
aarch64-linux-gnu-strings "$ko" | grep -oE '\$VERSION\$[0-9.:]+\$' | head -1 | sed 's/^/  /'
