#!/usr/bin/env python3
"""Add the rk1808 rows to the mainline drivers that are shared across socs.

    python3 mainline-7.2-rows.py <mainline-tree> <bsp-tree>

Idempotent. Called by mainline-7.2.sh.

Five drivers carry per-soc tables that mainline has for every rockchip part
except this one. Two of them are on the critical path and are done here:

  pmdomain   the npu node is power-domains = <&power RK1808_VD_NPU>, and dwc3's
             wrapper is RK1808_PD_PCIE, so nothing usb or npu probes without it
  usb2 phy   dwc3 waits on u2phy_otg for ever and gives up with
             "deferred probe timeout, ignoring dependency ... error -110"

pinctrl is in mainline-7.2-pinctrl.py, which is bigger. efuse and thermal are
only reported: nothing needed so far depends on them - the efuse matters for the
serial the transfer proxy reads, and tsadc for thermal throttling.

One thing does not translate. The bsp marks the vio domain with
DOMAIN_PX30_PROTECT, which expands to a DOMAIN_M taking an eighth "keepon"
argument that mainline's DOMAIN_M does not have - there is no equivalent
concept. vio is display and camera, neither of which exists on this board, so it
is declared with plain DOMAIN_PX30 and loses only the never-power-off flag.
"""
import os
import re
import sys

PMDOMAIN = """
/* rk1808, ported from the vendor bsp - see tools/rk1808-bootimg.
 *
 * The vio domain is DOMAIN_PX30_PROTECT in the bsp. That expands to a DOMAIN_M
 * with an eighth "keepon" argument which mainline does not have, so it is plain
 * DOMAIN_PX30 here. vio is display and camera; this board has neither.
 */
static const struct rockchip_domain_info rk1808_pm_domains[] = {
	[RK1808_VD_NPU]		= DOMAIN_PX30("npu",  BIT(15), BIT(15), BIT(2), false),
	[RK1808_PD_PCIE]	= DOMAIN_PX30("pcie", BIT(9),  BIT(9),  BIT(4), true),
	[RK1808_PD_VPU]		= DOMAIN_PX30("vpu",  BIT(13), BIT(13), BIT(7), false),
	[RK1808_PD_VIO]		= DOMAIN_PX30("vio",  BIT(14), BIT(14), BIT(8), false),
};

static const struct rockchip_pmu_info rk1808_pmu = {
	.pwr_offset = 0x18,
	.status_offset = 0x20,
	.req_offset = 0x64,
	.idle_offset = 0x6c,
	.ack_offset = 0x6c,

	.num_domains = ARRAY_SIZE(rk1808_pm_domains),
	.domain_info = rk1808_pm_domains,
};

"""

PMDOMAIN_MATCH = """	{
		.compatible = "rockchip,rk1808-power-controller",
		.data = (void *)&rk1808_pmu,
	},
"""


def span(s, start, end_re):
    i = s.find(start)
    if i < 0:
        return None
    i = s.rfind("\n", 0, i) + 1
    m = re.compile(end_re, re.M).search(s, i)
    return (i, m.end()) if m else None


def do_pmdomain(k72, kbsp):
    p = os.path.join(k72, "drivers/pmdomain/rockchip/pm-domains.c")
    s = open(p).read()
    if "rk1808_pmu" in s:
        print("    pmdomain   already ported")
        return
    if "rk1808-power.h" not in s:
        anchor = '#include <dt-bindings/power/px30-power.h>'
        assert anchor in s, "no px30-power.h include to anchor on"
        s = s.replace(anchor,
                      '#include <dt-bindings/power/rk1808-power.h>\n' + anchor, 1)
    # After px30, not before it. The file leads with px30 and then runs
    # rk3036, rk3066, rk3128 and so on, in both the pmu_info definitions and
    # the of_match table, so rk1808 belongs in the second slot rather than
    # ahead of the part the list starts from.
    m = re.search(r"static const struct rockchip_pmu_info px30_pmu = \{.*?\n\};\n", s,
                  re.S)
    assert m, "no px30_pmu anchor"
    s = s[:m.end()] + "\n" + PMDOMAIN.strip("\n") + "\n" + s[m.end():]

    m = re.search(r"\t\{\n\t\t\.compatible = \"rockchip,px30-power-controller\",\n"
                  r"\t\t\.data = \(void \*\)&px30_pmu,\n\t\},\n", s)
    assert m, "no px30 power-controller of_match entry"
    s = s[:m.end()] + PMDOMAIN_MATCH + s[m.end():]
    open(p, "w").write(s)
    print("    pmdomain   4 domains, pmu info and of_match added")


def do_usb2phy(k72, kbsp):
    p = os.path.join(k72, "drivers/phy/rockchip/phy-rockchip-inno-usb2.c")
    b = os.path.join(kbsp, "drivers/phy/rockchip/phy-rockchip-inno-usb2.c")
    s = open(p).read()
    if "rk1808_phy_cfgs" in s:
        print("    usb2 phy   already ported")
        return
    src = open(b, errors="replace").read()
    sp = span(src, "static const struct rockchip_usb2phy_cfg rk1808_phy_cfgs[]",
              r"^\};\n")
    assert sp, "could not extract rk1808_phy_cfgs"
    cfgs = src[sp[0]:sp[1]]

    # Six of the vendor initialisers name members mainline's
    # rockchip_usb2phy_port_cfg and rockchip_chg_det_reg do not have. They are
    # all vendor extensions and none is needed here:
    #
    #   bypass_dm_en, bypass_sel   dm bypass, for a usb2 hub arrangement
    #   iddig_output, iddig_en     forcing the otg id; this board's dwc3 is
    #                              dr_mode = "peripheral", so the id is not read
    #   vbus_det_en                vbus detection enable
    #   chg_mode                   battery charger detection mode
    #
    # Charger detection is the only one with a visible consequence, and the die
    # is a peripheral on a fixed host link, so nothing asks.
    dropped = []
    for m in ("bypass_dm_en", "bypass_sel", "iddig_output", "iddig_en",
              "vbus_det_en", "chg_mode"):
        cfgs, n = re.subn(r"\n\s*\.%s\s*=\s*\{[^}]*\},?" % m, "", cfgs)
        if n:
            dropped.append(m)

    cfgs = ("/* rk1808, ported from the vendor bsp - see tools/rk1808-bootimg.\n"
            " * %s dropped: vendor-only members, see the note in\n"
            " * mainline-7.2-rows.py.\n */\n" % ", ".join(dropped)
            + cfgs + "\n")
    anchor = "static const struct rockchip_usb2phy_cfg rk3128_phy_cfgs[]"
    if anchor not in s:
        anchor = "static const struct of_device_id rockchip_usb2phy_dt_match[]"
    assert anchor in s, "no anchor for the cfgs array"
    s = s.replace(anchor, cfgs + anchor, 1)
    m = re.search(r"\t\{ \.compatible = \"rockchip,px30-usb2phy\"[^\n]*\n", s)
    assert m, "no px30 usb2phy of_match entry"
    entry = ('\t{ .compatible = "rockchip,rk1808-usb2phy",'
             ' .data = &rk1808_phy_cfgs },\n')
    s = s[:m.start()] + entry + s[m.start():]
    open(p, "w").write(s)
    print("    usb2 phy   cfgs (%d lines) and of_match added"
          % cfgs.count("\n"))


REPORT = [
    ("efuse",   "drivers/nvmem/rockchip-efuse.c",     "rk1808"),
    ("thermal", "drivers/thermal/rockchip_thermal.c", "rk1808_tsadc_data"),
]


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    k72, kbsp = sys.argv[1], sys.argv[2]
    do_pmdomain(k72, kbsp)
    do_usb2phy(k72, kbsp)
    for label, rel, marker in REPORT:
        p = os.path.join(k72, rel)
        have = os.path.exists(p) and marker in open(p, errors="replace").read()
        print("    %-10s %s (not needed yet)"
              % (label, "present" if have else "absent"))


if __name__ == "__main__":
    main()
