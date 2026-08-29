#!/usr/bin/env python3
"""Adjust the board dts for 6.1, and emit a debug variant.

Called by build-kernel-6.1.sh with the path to rk3399pro-npu-evb-v10.dts in
the 6.1 tree. Idempotent: safe to run over an already adjusted file.

Each change is here for a reason that cost a boot to find.
"""
import os
import re
import sys

# This script used to append an override disabling &combphy and pinning dwc3 to
# high-speed, because drivers/phy/rockchip on develop-6.1 has nothing matching
# rockchip,rk1808-combphy - the device tree was kept and the driver dropped, and
# without a phy dwc3 stops with "failed to initialize core".
#
# combphy-6.1.sh puts that driver back, taken from develop-5.10. So the override
# is no longer wanted, and is only recognised here so a dts carrying it from an
# earlier run gets cleaned. It is worth removing rather than leaving: at 480Mbps
# instead of 5000, every rknn_init drags a 32MB model across the link.
USB2_MARKER = 'maximum-speed = "high-speed"'
USB2_BLOCK = re.compile(
    r"\n/\*\n \* 6\.1 declares rockchip,rk1808-combphy.*?"
    r"&usbdrd_dwc3 \{.*?\n\};\n", re.S)

OTG_RST = """
/*
 * Give the usb3 otg reset to the combphy, not to the dwc3 wrapper.
 *
 * Two nodes ask for <&cru SRST_USB3_OTG_A>: usbdrd3 as "usb3-otg" and combphy
 * as "otg-rst". Both ask exclusively - dwc3-of-simple through
 * of_reset_control_array_get(np, false, ...), the phy through
 * devm_reset_control_get() - and 6.1's reset core refuses the second caller
 * with a WARN at drivers/reset/core.c:766 and -EBUSY. 4.4 and 5.10 allowed the
 * duplicate silently, which is why the same device tree works there.
 *
 * Whoever loses depends on probe order. Built in, the combphy wins and the dwc3
 * wrapper gets nothing, so no gadget comes up at all - no shell, no transfer,
 * nothing to read on a die whose only console is that gadget. As a module
 * loaded by hand the combphy loses instead, which is why that looked fine.
 *
 * The phy is the one that needs it. phy_u3_init asserts the controller reset,
 * brings the PLL up, and deasserts it once lane0 is ready; without it the PLL
 * never locks, phy_init returns -110 and dwc3 fails with "failed to initialize
 * core" anyway. Dropping it from the phy was tried first and produced exactly
 * that. dwc3-of-simple asks with optional=true, so it is happy with none, and
 * the phy hands the controller back deasserted before dwc3's core init runs -
 * which is the order 4.4 ends up in.
 */
&usbdrd3 {
\t/delete-property/ resets;
\t/delete-property/ reset-names;
};
"""


def strip_absent_regulator(s):
    """Remove vdd_npu_1, the syr827 at i2c 0x40 that this board does not have.

    Sheet 12 of som-sch-v1.3.pdf shows one i2c regulator on the npu rail,
    U2206, which is the tcs452x@1c already described. The syr837 on the som is
    U2200 and feeds VDD_CPU_B on the rk3399 side.

    On 4.4 the failed probe was merely noisy. On 6.1 device links make it a
    hard dependency and the npu never probes at all:

        ffbc0000.npu   platform: supplier 1-0040 not ready
    """
    if "vdd_npu_1" not in s:
        return s, False
    s = re.sub(r"\n\tvdd_npu_1: syr837@40 \{.*?\n\t\};\n", "\n", s, flags=re.S)
    s = re.sub(r"[ \t]*npu_1-supply = <&vdd_npu_1>;\n", "", s)
    return s, True


def nest_vsel_group(s):
    """Put pinctrl groups back inside a function node, so pinctrl finds them.

    rockchip's pinctrl wants two levels under &pinctrl - a function node
    containing one or more group nodes:

        &pinctrl {
            vdd-npu-sleep {                       <- function
                vsel_gpio: vsel-gpio {            <- group
                    rockchip,pins = <...>;

    The 4.4 board dts has that. develop-6.1, 6.6 and 6.12 all flattened it by
    one level, putting the group directly under &pinctrl, so the driver reads
    vsel-gpio as a function with no groups and refuses it:

        rockchip-pinctrl pinctrl: unable to find group for node vsel-gpio

    That fails pinctrl for the tcs4525 at i2c1 0x1c, which is vdd_npu, so its
    probe fails, so the npu never gets its supply:

        platform ffbc0000.npu: deferred probe pending:
                               platform: supplier 1-001c not ready

    and galcore loads but never gets a /dev/galcore. This is why the npu does
    not come up on rockchip's own board dts on any branch after 4.4.

    Every flattened group is fixed, not just vsel_gpio: pwr-key is flattened the
    same way and fails the same way, and on mainline that failure takes the whole
    pinctrl probe down rather than just one consumer.

    The function node is named after the group with a "-grp" suffix, which is
    only a label - the driver cares that there are two levels, not what the
    upper one is called.
    """
    out = []
    fixed = 0
    for m in re.finditer(r"\n\t([a-z0-9_]+: )?([a-z0-9-]+) \{\n"
                         r"((?:\t\trockchip,pins[^\n]*\n(?:\t\t\t[^\n]*\n)*)+)"
                         r"\t\};\n", s):
        out.append(m)
    for m in reversed(out):
        label, name, body = m.group(1) or "", m.group(2), m.group(3)
        body = "".join("\t" + l if l.strip() else l
                       for l in body.splitlines(keepends=True))
        s = s[:m.start()] + (
            "\n\t%s-grp {\n" % name +
            "\t\t%s%s {\n" % (label, name) +
            body +
            "\t\t};\n"
            "\t};\n"
        ) + s[m.end():]
        fixed += 1
    return s, fixed


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: dts-6.1.py <rk3399pro-npu-evb-v10.dts>")
    p = sys.argv[1]
    s = open(p).read()

    s, stripped = strip_absent_regulator(s)
    if stripped:
        print("  dts: vdd_npu_1 removed, not fitted on this board")
    else:
        print("  dts: vdd_npu_1 already absent")

    # Undo the old workaround if this dts still carries it, so a tree adjusted
    # before the driver was ported converges on the same result.
    if USB2_MARKER in s:
        s, n = USB2_BLOCK.subn("", s)
        if n:
            print("  dts: usb2-only override removed, combphy driver is back")
        else:
            print("  dts: WARNING maximum-speed set outside the block this "
                  "script wrote - left alone, check by hand")
    else:
        print("  dts: no usb2-only override to undo")

    s, nested = nest_vsel_group(s)
    if nested:
        print("  dts: %d pinctrl group(s) nested so the driver finds them"
              % nested)
    else:
        print("  dts: pinctrl groups already nested")

    if "/delete-property/ resets" in s:
        print("  dts: otg reset override already present")
    else:
        s = s.rstrip() + "\n" + OTG_RST
        print("  dts: usbdrd3 no longer claims the otg reset, phy keeps it")

    # What the 5Gbps link depends on, and both come from the 4.4 board files:
    # the board enabling the phy, and rk3399pro-npu.dtsi asking dwc3 for it. If
    # either goes away usb quietly drops to 480, which is much easier to miss
    # than a boot failure.
    if 'status = "okay"' not in s.split("&combphy {")[1][:60]:
        print("  dts: WARNING &combphy not enabled - usb will run at 480")
    else:
        print("  dts: &combphy enabled, dwc3 keeps its usb3 phy")

    open(p, "w").write(s)

    # A variant that goes straight to a shell, for when the console is wanted
    # without userspace in the way. rdinit, not init: this is an initramfs and
    # never switches root, so init= is ignored and /init runs regardless.
    dbg = os.path.join(os.path.dirname(p), "rk3399pro-npu-dbg.dts")
    open(dbg, "w").write(s.replace("init=/init", "rdinit=/bin/sh"))
    print("  dts: %s written with rdinit=/bin/sh" % os.path.basename(dbg))


if __name__ == "__main__":
    main()
