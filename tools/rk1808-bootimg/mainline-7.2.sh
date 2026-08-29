#!/bin/bash
# Install rk1808 support into a mainline tree.
#
# Mainline has nothing for this soc - the clock driver, the cru bindings, the
# dtsi and every per-driver table are vendor-only - so this copies them in from
# a bsp tree and adds the rk1808 rows to the drivers that are shared.
#
#   K72=<mainline tree> KBSP=<bsp tree> bash tools/mainline-7.2.sh
#
# Idempotent. Whole files are copied; shared drivers are handled by
# mainline-7.2-rows.py, which is where the real work is.
#
# The console does not depend on any of it: the board bootargs carry
#
#     earlycon=uart8250,mmio32,0xff550000
#
# which pokes the uart directly, so even a kernel that dies before the clock
# driver probes will say where. That is the whole reason this is tractable
# unattended - see the serial console note in the README.
set -e
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
K72="${K72:-$ROOT/../npu-research/linux-7.2}"
KBSP="${KBSP:-$ROOT/../npu-research/kernel-6.12}"
D=arch/arm64/boot/dts/rockchip

[ -d "$K72" ] || { echo "no mainline tree at $K72" >&2; exit 1; }
[ -d "$KBSP" ] || { echo "no bsp tree at $KBSP" >&2; exit 1; }

echo "=== whole files ==="
# dt-bindings headers the vendor dts chain includes and mainline does not have
for h in clock/rk1808-cru.h power/rk1808-power.h \
         soc/rockchip-system-status.h suspend/rockchip-rk1808.h; do
  src="$KBSP/include/dt-bindings/$h"
  dst="$K72/include/dt-bindings/$h"
  if [ ! -f "$src" ]; then echo "  MISSING in bsp: $h" >&2; exit 1; fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  dt-bindings/$h"
done

# the soc and board description
for f in rk1808.dtsi rk1808-dram-default-timing.dtsi \
         rk3399pro-npu.dtsi rk3399pro-npu-evb-v10.dts; do
  cp "$KBSP/$D/$f" "$K72/$D/$f"
  echo "  $f  ($(wc -l < "$K72/$D/$f") lines)"
done

# the clock driver
cp "$KBSP/drivers/clk/rockchip/clk-rk1808.c" "$K72/drivers/clk/rockchip/"
echo "  clk-rk1808.c  ($(wc -l < "$K72/drivers/clk/rockchip/clk-rk1808.c") lines)"

echo "=== build glue ==="
mk="$K72/drivers/clk/rockchip/Makefile"
if grep -q "clk-rk1808.o" "$mk"; then
  echo "  clk Makefile already has it"
else
  printf 'obj-$(CONFIG_CLK_RK1808)\t+= clk-rk1808.o\n' >> "$mk"
  echo "  clk Makefile: added under CONFIG_CLK_RK1808"
fi

ch="$K72/drivers/clk/rockchip/clk.h"
if grep -q "RK1808_CLKSEL_CON" "$ch"; then
  echo "  clk.h already has the rk1808 register map"
else
  # clk-rk1808.c is the only user of these, and mainline's clk.h has the same
  # block for every other rockchip part. Anchored on RK2928_PLL_CON, which the
  # comment above this block says rk1808 shares its layout with.
  python3 - "$ch" <<'PY'
import sys

p = sys.argv[1]
s = open(p).read()
anchor = "#define RK2928_PLL_CON(x)"
assert anchor in s, "no RK2928_PLL_CON anchor in clk.h"
block = """/* register positions for RK1808, shared with the RK2928 family layout */
#define RK1808_PLL_CON(x)		((x) * 0x4)
#define RK1808_MODE_CON			0xa0
#define RK1808_MISC_CON			0xa4
#define RK1808_MISC1_CON		0xa8
#define RK1808_GLB_SRST_FST		0xb8
#define RK1808_GLB_SRST_SND		0xbc
#define RK1808_CLKSEL_CON(x)		((x) * 0x4 + 0x100)
#define RK1808_CLKGATE_CON(x)		((x) * 0x4 + 0x230)
#define RK1808_SOFTRST_CON(x)		((x) * 0x4 + 0x300)
#define RK1808_SDMMC_CON0		0x380
#define RK1808_SDMMC_CON1		0x384
#define RK1808_SDIO_CON0		0x388
#define RK1808_SDIO_CON1		0x38c
#define RK1808_EMMC_CON0		0x390
#define RK1808_EMMC_CON1		0x394

#define RK1808_PMU_PLL_CON(x)		((x) * 0x4 + 0x4000)
#define RK1808_PMU_MODE_CON		0x4020
#define RK1808_PMU_CLKSEL_CON(x)	((x) * 0x4 + 0x4040)
#define RK1808_PMU_CLKGATE_CON(x)	((x) * 0x4 + 0x4080)

"""
open(p, "w").write(s.replace(anchor, block + anchor, 1))
PY
  echo "  clk.h: rk1808 register map added"
fi

kc="$K72/drivers/clk/rockchip/Kconfig"
if grep -q "CLK_RK1808" "$kc"; then
  echo "  clk Kconfig already has it"
else
  cat >> "$kc" <<'KEOF'

config CLK_RK1808
	bool "Rockchip RK1808 clock controller support"
	depends on ARCH_ROCKCHIP || COMPILE_TEST
	default y
	select COMMON_CLK_ROCKCHIP
	help
	  Build the driver for RK1808 Clock Driver.
KEOF
  echo "  clk Kconfig: CLK_RK1808 added"
fi

# the dts Makefile - no rk1808 board is listed, so ask for it by name at build
# time instead of adding it here, the same way the 6.1 and 6.12 builds do

echo "=== clk driver, ported to the mainline framework ==="
python3 "$ROOT/tools/mainline-7.2-clk.py" "$K72"

echo "=== pinctrl ==="
python3 "$ROOT/tools/mainline-7.2-pinctrl.py" "$K72" "$KBSP"

echo "=== rk1808 rows in the shared drivers ==="
python3 "$ROOT/tools/mainline-7.2-rows.py" "$K72" "$KBSP"

echo "=== board dts, shared fixes then mainline console ==="
# the otg reset ownership and the vsel_gpio nesting are the same bugs on any
# tree, so the same script fixes them here
python3 "$ROOT/tools/dts-6.1.py" "$K72/$D/rk3399pro-npu-evb-v10.dts" | sed 's/^/  /'
python3 "$ROOT/tools/mainline-7.2-dts.py" "$K72/$D/rk3399pro-npu-evb-v10.dts"

echo "=== combphy ==="
K61="$K72" bash "$ROOT/tools/combphy-6.1.sh" | sed 's/^/  /'
