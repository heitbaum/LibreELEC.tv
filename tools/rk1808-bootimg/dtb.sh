#!/bin/bash
# Board dtb: the shipped one, plus the few things it is missing.
#
# The shipped dtb was built in December 2019 and the kernel tree has moved on,
# so a node the newer drivers look for is simply absent. Rather than ship the
# tree's rk3399pro-npu-evb-v10.dtb wholesale - which describes a second npu
# core supply this board does not have - take the board's own dtb and add only
# what is missing and safe.
#
# Patch the blob with fdtput rather than decompiling to dts and recompiling.
# That round trip is lossy on this dtb: recompiling even an UNMODIFIED
# decompile gives 42296 bytes against the original 42224, and the result boots
# with every clock reference broken -
#
#   clk: couldn't get clock 0 for /phy@ff380000
#   rockchip-pvtm fe000000.syscon:npu-pvtm: failed to get clk 0 npu
#
# because dtc cannot tell a phandle from an integer in a decompiled tree.
# fdtput edits the blob in place and leaves everything else byte for byte.
#
# NOT added: vdd_npu_1 / syr837@40. Sheet 12 of som-sch-v1.3.pdf shows the npu
# power tree as seven regulators, of which exactly one is on the die's i2c -
# U2206, a CS4525, which is the tcs452x@1c already in the dtb. The syr837 on
# this board is U2200, and it feeds VDD_CPU_B on the rk3399 side, on the
# rk3399's own pmic i2c. There is nothing at 0x40 on the die's bus, so adding
# that node would leave npu_1-supply unresolvable and hang galcore's probe.
set -e
set -o pipefail
cd "$(dirname "$0")/.."

SRC="${SRC:-unpacked/resource/rk-kernel.dtb}"
OUT="${OUT:-build/rk-kernel.dtb}"
mkdir -p build
cp "$SRC" "$OUT"

PM=/cpus/cpu@0/power-model

if fdtget "$OUT" "$PM" compatible >/dev/null 2>&1; then
  echo "  power-model already present"
else
  # rockchip_ipa.c looks for a power-model child of the cpu node and logs
  # "failed to find power_model node" without one. The npu already has its
  # own; only the cpu is missing. These are soc characterisation values from
  # the tree's rk1808.dtsi, so they carry over to any rk1808.
  fdtput -c "$OUT" "$PM"
  fdtput -t s "$OUT" "$PM" compatible "simple-power-model"
  fdtput -t x "$OUT" "$PM" ref-leakage 0x1f
  fdtput -t x "$OUT" "$PM" static-coefficient 0x186a0
  fdtput -t s "$OUT" "$PM" thermal-zone "soc-thermal"
  fdtput -t x "$OUT" "$PM" ts 0x91d98 0x3ad9a 0xfffff66e 0x46
  echo "  power-model added to /cpus/cpu@0"
fi

# Not added: the cpu opp table's rockchip,pvtm-* properties. They exist in
# rk1808.dtsi and are absent here, which is why the boot says
# "cpu cpu0: Failed to get pvtm" - but adding them does not help. To take a
# pvtm reading the driver has to set the rail to rockchip,pvtm-volt, and on
# this board it cannot: cpu-supply is vdd-cpu, a regulator-fixed at
# 850000-850000 uV, which is U2202 on sheet 12, an SY8088AAC with an
# enable pin and a fixed feedback divider. Adding them just gets the driver
# one step further before it gives up:
#
#   cpu cpu0: Failed to set pvtm_volt
#   cpu cpu0: Failed to get pvtm
#
# vdd-log behind the dmc is fixed the same way. The npu rail is the one
# adjustable supply on the die's i2c - the tcs452x - and its pvtm works:
#
#   galcore ffbc0000.npu: temp=48125, pvtm=83861 (84459 + -598)
#
# So cpu and dmc voltage binning is not something this board can do, and the
# two warnings are permanent.

echo "  $OUT  $(stat -c %s "$OUT") bytes  (source $(stat -c %s "$SRC"))"

echo "=== check: nothing else moved ==="
dtc -I dtb -O dts -s "$SRC" -o build/.a.dts 2>/dev/null
dtc -I dtb -O dts -s "$OUT" -o build/.b.dts 2>/dev/null
# grep -c exits 1 on a zero count, which set -e would treat as fatal
added=$(diff build/.a.dts build/.b.dts | grep -c "^>" || true)
removed=$(diff build/.a.dts build/.b.dts | grep -c "^<" || true)
echo "  lines added: $added   lines removed: $removed   (removed must be 0)"
[ "$removed" -eq 0 ] || { echo "  ERROR: the patch removed something" >&2; exit 1; }
rm -f build/.a.dts build/.b.dts
