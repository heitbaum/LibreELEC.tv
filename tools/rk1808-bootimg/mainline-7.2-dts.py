#!/usr/bin/env python3
"""Make the vendor board dts usable on mainline.

    python3 mainline-7.2-dts.py <rk3399pro-npu-evb-v10.dts>

Idempotent. Called by mainline-7.2.sh.

The vendor console is an out of tree fiq debugger on ttyFIQ0, and mainline has
no such thing, so the console has to move to the plain 8250 the same uart is
also described as. uart2 at 0xff550000 is serial2, so ttyS2.

earlycon is left alone and is the reason any of this is debuggable: it pokes
0xff550000 directly with no driver, no clock and no device tree, so it prints
from decompression onwards even if everything after it fails. With no valid
console= it also never hands over, so the whole boot still comes out.

This does not apply the fixes shared with the bsp builds - the otg reset
ownership and the vsel_gpio nesting are in dts-6.1.py, which runs on the same
file.
"""
import os
import re
import sys

# While mainline's pinctrl-rockchip had no rk1808 data, uart2's
# pinctrl-0 = <&uart2m0_xfer> could not be applied and the 8250 never probed, so
# this block also deleted the pinctrl properties. u-boot has already muxed those
# pins - that is why earlycon works on them - so the console did not need the
# state, and dropping it bought a shell while pinctrl was still outstanding.
# With the rk1808 pinctrl data installed that is no longer true and the deletion
# is gone: the uart takes its proper state like everything else.
UART_OKAY = """
/*
 * The console.
 *
 * rk3399pro-npu.dtsi leaves uart2 status = "disabled", and the vendor board dts
 * never enables it - what it enables is the fiq-debugger node, which borrows the
 * same pins through pinctrl-0 = <&uart2m0_xfer> and rockchip,serial-id = <2>.
 * Mainline has no fiq debugger, so without this the uart is simply off: no
 * "ttyS2 at MMIO" line, no /dev/console, and init dies with
 * "Attempted to kill init!".
 *
 * Watch out for the near miss when checking whether this is already present:
 * "&uart2" is a substring of "&uart2m0_xfer", so a plain `in` test says yes on
 * a dts that has only the pinctrl reference. Match the node reference itself.
 */
&uart2 {
\tstatus = "okay";
};
"""


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    p = sys.argv[1]
    s = open(p).read()

    if "console=ttyFIQ0" in s:
        s = s.replace("console=ttyFIQ0", "console=ttyS2,1500000", 1)
        print("    console moved from ttyFIQ0 to ttyS2")
    elif "console=ttyS2" in s:
        print("    console already ttyS2")
    else:
        print("    WARNING no console= in bootargs, check by hand")

    if "earlycon=uart8250,mmio32,0xff550000" in s:
        print("    earlycon kept - prints with no driver at all")
    else:
        s = re.sub(r'(bootargs = ")', r'\1earlycon=uart8250,mmio32,0xff550000 ', s, count=1)
        print("    earlycon added")

    # No clk_ignore_unused. It was needed while the console was earlycon only:
    # earlycon holds no clock reference, so late_initcall's "Disabling unused
    # clocks" gated the uart and the log stopped mid boot looking exactly like a
    # hang. Once pinctrl knows the soc, ttyS2 probes and claims the clock, and
    # the boot is clean without it. Worth putting back by hand when bisecting an
    # early hang, which is the one case it earns its keep.
    if "clk_ignore_unused" in s:
        s = s.replace(" clk_ignore_unused", "", 1)
        print("    clk_ignore_unused removed, ttyS2 claims the clock itself")

    # Enable the uart. The check must match the node reference, not the bare
    # string: "&uart2" also occurs inside "&uart2m0_xfer", which is how an
    # earlier version of this convinced itself the uart was already on while the
    # compiled dtb said status = "disabled".
    if re.search(r"&uart2\s*\{", s):
        print("    uart2 override already present")
    else:
        s = s.rstrip() + "\n" + UART_OKAY
        print("    uart2 enabled so the 8250 can probe")

    open(p, "w").write(s)

    # dts-6.1.py writes the rdinit variant before this script runs, so it
    # carries the vendor console and none of the fixes above. Regenerate it from
    # the file as it now stands.
    dbg = os.path.join(os.path.dirname(p), "rk3399pro-npu-dbg.dts")
    open(dbg, "w").write(s.replace("init=/init", "rdinit=/bin/sh"))
    print("    %s regenerated with the mainline console"
          % os.path.basename(dbg))


if __name__ == "__main__":
    main()
