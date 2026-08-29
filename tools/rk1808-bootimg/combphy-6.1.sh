#!/bin/bash
# Put the rk1808 combphy driver back into a 6.1 tree, so usb runs at 5Gbps.
#
# 6.1 still describes the phy - phy@ff380000 in rk1808.dtsi, compatible
# rockchip,rk1808-combphy, with its refclk, all five named resets and both grf
# phandles - and rk3399pro-npu.dtsi still wires dwc3 to it:
#
#     phys = <&u2phy_otg>, <&combphy PHY_TYPE_USB3>;
#     phy-names = "usb2-phy", "usb3-phy";
#
# but drivers/phy/rockchip on develop-6.1 has no driver matching that
# compatible. The device tree was kept and the driver was dropped. Without it
# the phy never registers and dwc3 stops with "failed to initialize core", so
# the gadget has to be pinned to usb2 - which is what this replaces. The die
# then enumerates at 480Mbps instead of 5000, and every rknn_init pushes a 32MB
# model across that link.
#
# The driver to bring back is phy-rockchip-inno-combphy.c. It is on develop-4.4,
# develop-4.19 and develop-5.10 and gone at 6.1. Take 5.10: it is the newest
# that has it, it still binds rockchip,rk1808-combphy, and it is only 7 lines
# from 4.19 and 45 from 4.4 - the driver barely moved, so the whole gap is the
# kernel api rather than the hardware support. It compiles against 6.1 with no
# changes at all.
#
#   K61=<6.1 tree> bash tools/combphy-6.1.sh
#
# Idempotent. Set COMBPHY_SRC to a local copy to skip the download.
set -e
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
K61="${K61:-$ROOT/../npu-research/kernel-6.1}"
BRANCH="${COMBPHY_BRANCH:-develop-5.10}"
DRV=drivers/phy/rockchip/phy-rockchip-inno-combphy.c
URL="https://raw.githubusercontent.com/rockchip-linux/kernel/$BRANCH/$DRV"

[ -d "$K61" ] || { echo "no 6.1 tree at $K61" >&2; exit 1; }

echo "=== the phy this restores ==="
if grep -q "rk1808-combphy" "$K61/arch/arm64/boot/dts/rockchip/rk1808.dtsi"; then
  echo "  rk1808.dtsi already describes rockchip,rk1808-combphy"
else
  echo "  rk1808.dtsi has no combphy node - wrong tree?" >&2; exit 1
fi

echo "=== driver ==="
if [ -f "$K61/$DRV" ] && grep -q "rk1808_combphy_cfgs" "$K61/$DRV"; then
  echo "  already installed, $(wc -l < "$K61/$DRV") lines"
elif [ -n "${COMBPHY_SRC:-}" ]; then
  cp "$COMBPHY_SRC" "$K61/$DRV"
  echo "  installed from $COMBPHY_SRC, $(wc -l < "$K61/$DRV") lines"
else
  curl -fsS --max-time 120 -o "$K61/$DRV" "$URL"
  # a 404 lands as an html page, not an error, so check for the real thing
  grep -q "rk1808_combphy_cfgs" "$K61/$DRV" || {
    echo "  $URL did not return the driver" >&2; rm -f "$K61/$DRV"; exit 1; }
  echo "  fetched from $BRANCH, $(wc -l < "$K61/$DRV") lines"
fi

echo "=== compat fixes ==="
# 6.1 needs none of these; 6.12 needs both. Applied by detecting the tree rather
# than by version number, so this keeps working as the base moves.
drv="$K61/$DRV"

# 6.12 no longer reaches platform_device.h through of_device.h, and the driver
# relied on that: "invalid use of undefined type struct platform_device".
if grep -q "#include <linux/platform_device.h>" "$drv"; then
  echo "  platform_device.h already included"
else
  sed -i 's|#include <linux/of_device.h>|#include <linux/of_device.h>\n#include <linux/platform_device.h>|' "$drv"
  echo "  platform_device.h include added"
fi

# 6.12 made phy_provider's of_xlate take a const of_phandle_args.
if grep -q "const struct of_phandle_args" "$K61/include/linux/phy/phy.h"; then
  if grep -q "const struct of_phandle_args \*args" "$drv"; then
    echo "  of_xlate already takes const args"
  else
    sed -i 's|\(rockchip_combphy_xlate(struct device \*dev,\)|\1|; s|^\t\t\t\t\t  struct of_phandle_args \*args)|\t\t\t\t\t  const struct of_phandle_args *args)|' "$drv"
    grep -q "const struct of_phandle_args \*args" "$drv" \
      && echo "  of_xlate args made const" \
      || { echo "  could not make of_xlate args const - check by hand" >&2; exit 1; }
  fi
else
  echo "  this tree's of_xlate takes non-const args, nothing to do"
fi

# platform_driver.remove returns void from 6.11 on. The driver's remove only
# tears down a sysfs group and can never fail, so dropping the return value
# loses nothing.
if grep -q "void (\*remove)(struct platform_device \*)" "$K61/include/linux/platform_device.h"; then
  if grep -q "^static void rockchip_combphy_remove" "$drv"; then
    echo "  remove already returns void"
  else
    python3 - "$drv" <<'PY'
import re
import sys

p = sys.argv[1]
s = open(p).read()
m = re.search(r"static int (rockchip_combphy_remove\(struct platform_device \*pdev\)\s*\{.*?\n\})",
              s, re.S)
assert m, "remove not matched"
body = m.group(1).replace("\n\treturn 0;\n", "\n")
s = s[:m.start()] + "static void " + body + s[m.end():]
open(p, "w").write(s)
PY
    echo "  remove converted to void"
  fi
else
  echo "  this tree's remove still returns int, nothing to do"
fi

echo "=== build glue ==="
mk="$K61/drivers/phy/rockchip/Makefile"
if grep -q "PHY_ROCKCHIP_INNO_COMBPHY" "$mk"; then
  echo "  Makefile rule already present"
else
  printf 'obj-$(CONFIG_PHY_ROCKCHIP_INNO_COMBPHY)\t+= phy-rockchip-inno-combphy.o\n' >> "$mk"
  echo "  Makefile rule added"
fi

kc="$K61/drivers/phy/rockchip/Kconfig"
if grep -q "PHY_ROCKCHIP_INNO_COMBPHY" "$kc"; then
  echo "  Kconfig stanza already present"
else
  # verbatim from develop-5.10, so the symbol name and deps match what the
  # driver was built with there
  cat >> "$kc" <<'KEOF'

config PHY_ROCKCHIP_INNO_COMBPHY
	tristate "Rockchip INNO USB 3.0 and PCIe COMBPHY Driver"
	depends on (ARCH_ROCKCHIP && OF) || COMPILE_TEST
	select GENERIC_PHY
	help
	  Enable this to support the Rockchip SoCs COMBPHY.
	  If unsure, say N.
KEOF
  echo "  Kconfig stanza added"
fi

echo "  done - build-kernel-6.1.sh enables CONFIG_PHY_ROCKCHIP_INNO_COMBPHY"
