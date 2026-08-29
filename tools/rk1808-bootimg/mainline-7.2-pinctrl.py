#!/usr/bin/env python3
"""Add rk1808 pinctrl support to a mainline tree.

    python3 mainline-7.2-pinctrl.py <mainline-tree> <bsp-tree>

Idempotent. Called by mainline-7.2.sh.

This is the last blocker for everything except the console. Without it every
peripheral that names a pinctrl state sits in deferred probe for ever:

    dwc3-of-simple usb: deferred probe timeout, ignoring dependency
    ff500000.i2c: deferred probe pending: wait for supplier /pinctrl/i2c1/i2c1-xfer
    gpio-keys:    deferred probe pending: wait for supplier /pinctrl/pwr-key

and i2c1 is how vdd_npu is reached, so the npu depends on it too.

Almost all of it transplants unchanged: mainline's rockchip_pin_ctrl has every
field the vendor rk1808 definition sets, and in all three switches on
ctrl->type the bsp groups RK1808 with RV1108/RK3188/RK3288, which mainline also
has. Two things do not transplant:

  - mainline has no slew_rate_calc_reg at all, so rk1808_calc_slew_rate_reg_and_bit
    and its RK1808_SR_* defines are left behind rather than carried as dead code
    the compiler would reject as unused.
  - RK1808 is not in mainline's rockchip_pinctrl_type, so it is added.
"""
import os
import re
import sys


def span(s, start, end_re):
    """From the line containing `start` to the first line matching end_re."""
    i = s.find(start)
    if i < 0:
        return None
    i = s.rfind("\n", 0, i) + 1
    m = re.compile(end_re, re.M).search(s, i)
    if not m:
        return None
    return i, m.end()


def take(s, start, end_re, label):
    sp = span(s, start, end_re)
    if not sp:
        raise SystemExit("could not extract %s" % label)
    return s[sp[0]:sp[1]]


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    k72, kbsp = sys.argv[1], sys.argv[2]
    src = os.path.join(kbsp, "drivers/pinctrl/pinctrl-rockchip.c")
    dst = os.path.join(k72, "drivers/pinctrl/pinctrl-rockchip.c")
    hdr = os.path.join(k72, "drivers/pinctrl/pinctrl-rockchip.h")
    for f in (src, dst, hdr):
        if not os.path.exists(f):
            raise SystemExit("missing %s" % f)

    b = open(src, errors="replace").read()
    s = open(dst).read()
    h = open(hdr).read()

    if "rk1808_pin_ctrl" in s:
        print("    pinctrl already ported")
        return

    # the pull and drive calculations, then the schmitt one - deliberately
    # skipping the slew rate block in between
    pull_drv = take(b, "#define RK1808_PULL_PMU_OFFSET",
                    r"^\}\n(?=\n#define RK1808_SR_PMU_OFFSET)", "pull/drv")
    schmitt = take(b, "#define RK1808_SCHMITT_PMU_OFFSET", r"^\}\n", "schmitt")
    routes = take(b, "static struct rockchip_mux_route_data rk1808_mux_route_data[]",
                  r"^\};\n", "mux routes")
    banks = take(b, "static struct rockchip_pin_bank rk1808_pin_banks[]",
                 r"^\};\n", "pin banks")
    ctrl = take(b, "static struct rockchip_pin_ctrl rk1808_pin_ctrl",
                r"^\};\n", "pin ctrl")

    # mainline has no slew rate hook
    ctrl = re.sub(r"\n\t\.slew_rate_calc_reg\t= rk1808_calc_slew_rate_reg_and_bit,",
                  "", ctrl)

    blob = ("/* rk1808, ported from the vendor bsp - see tools/rk1808-bootimg */\n"
            + pull_drv + "\n" + schmitt + "\n" + routes + "\n" + banks + "\n" + ctrl
            + "\n")

    anchor = "static struct rockchip_pin_bank px30_pin_banks[] = {"
    if anchor not in s:
        raise SystemExit("no px30_pin_banks anchor to insert before")
    s = s.replace(anchor, blob + anchor, 1)

    # join the RV1108/RK3188 group in every switch on ctrl->type. The bsp puts
    # RK1808 immediately before RK3188 in each, and position inside a
    # fallthrough group makes no difference anyway.
    n = s.count("\tcase RK3188:\n")
    s = s.replace("\tcase RK3188:\n", "\tcase RK1808:\n\tcase RK3188:\n")
    print("    joined the RV1108/RK3188 group in %d switches" % n)

    # and the of_match entry
    m = re.search(r"(\t\{ \.compatible = \"rockchip,px30-pinctrl\",\n"
                  r"\s*\.data = [^}]*\},\n)", s)
    if m:
        entry = ('\t{ .compatible = "rockchip,rk1808-pinctrl",\n'
                 '\t\t.data = &rk1808_pin_ctrl },\n')
        s = s[:m.start()] + entry + s[m.start():]
        print("    of_match entry added")
    else:
        raise SystemExit("no px30 of_match entry to insert before")

    open(dst, "w").write(s)

    if "\tRK1808,\n" in h:
        print("    RK1808 already in rockchip_pinctrl_type")
    else:
        assert "\tRK3188,\n" in h, "no RK3188 in the type enum"
        h = h.replace("\tRK3188,\n", "\tRK1808,\n\tRK3188,\n", 1)
        open(hdr, "w").write(h)
        print("    RK1808 added to rockchip_pinctrl_type")

    print("    %d lines of rk1808 pinctrl data installed" % blob.count("\n"))


if __name__ == "__main__":
    main()
