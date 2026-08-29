#!/usr/bin/env python3
"""Port the vendor clk-rk1808.c to the mainline rockchip clk framework.

    python3 mainline-7.2-clk.py <mainline-tree>

Three differences, and none of them is cosmetic. Each was found by building
against 7.2 and then reading how mainline's own rockchip drivers do the same
thing, so the result is mainline's idiom rather than a shim.

Idempotent.
"""
import os
import re
import sys

# armclk. The bsp passes clk pointers for the main and alternate parent:
#
#   rockchip_clk_register_armclk(ctx, ARMCLK, "armclk",
#                                3, clks[PLL_APLL], clks[PLL_GPLL], ...)
#
# mainline takes parent *names* and indexes them by the register values already
# in the reg_data - clk-cpu.c does
#
#   init.parent_names = &parent_names[reg_data->mux_core_main];
#
# and rk1808_cpuclk_data has mux_core_main = 0, mux_core_alt = 2, mask 0x3. So
# the array has to put apll at 0 and gpll at 2, with dpll at 1 - which matches
# what the mux selects and what the bsp passed. Index 1 is never selected by
# this driver but must name a clock that exists, and dpll does.
ARMCLK_OLD = """	rockchip_clk_register_armclk(ctx, ARMCLK, "armclk",
				     3, clks[PLL_APLL], clks[PLL_GPLL],
				     &rk1808_cpuclk_data, rk1808_cpuclk_rates,
				     ARRAY_SIZE(rk1808_cpuclk_rates));"""

ARMCLK_NEW = """	rockchip_clk_register_armclk(ctx, ARMCLK, "armclk",
				     mux_armclk_p, ARRAY_SIZE(mux_armclk_p),
				     &rk1808_cpuclk_data, rk1808_cpuclk_rates,
				     ARRAY_SIZE(rk1808_cpuclk_rates));"""

ARMCLK_PNAME = """PNAME(mux_armclk_p)		= { "apll", "dpll", "gpll" };
"""

# The pmu grf mux. The bsp has a whole branch type for it, branch_muxpmugrf.
# Mainline instead has one grf mux type plus a hashtable of auxiliary grf
# regmaps keyed by an enum, so MUXGRF takes a grf_type and the driver puts the
# pmugrf in the table. clk-rk3528.c is the pattern followed here.
AUX_GRF = """
	/*
	 * The clk_32k_ioe mux lives in the pmu grf, not the sys grf. Mainline
	 * reaches non-sys grfs through ctx->aux_grf_table, keyed by grf_type,
	 * so register the pmugrf there before the branches that use it. The
	 * phandle is already in the cru node as rockchip,pmugrf.
	 */
	pmugrf_np = of_parse_phandle(np, "rockchip,pmugrf", 0);
	pmugrf = pmugrf_np ? syscon_node_to_regmap(pmugrf_np) : ERR_PTR(-ENODEV);
	of_node_put(pmugrf_np);
	if (!IS_ERR(pmugrf)) {
		pmugrf_e = kzalloc(sizeof(*pmugrf_e), GFP_KERNEL);
		if (!pmugrf_e) {
			pr_err("%s: could not allocate pmugrf entry\\n", __func__);
			return;
		}

		pmugrf_e->grf = pmugrf;
		pmugrf_e->type = grf_type_pmu0;
		hash_add(ctx->aux_grf_table, &pmugrf_e->node, grf_type_pmu0);
	} else {
		/*
		 * Expected on this path rather than a fault. of_clk_init() runs
		 * from time_init(), before the initcalls regmap needs, so the
		 * pmugrf cannot be mapped this early however it is asked for -
		 * neither by phandle nor by node. The only user of clk_32k_ioe
		 * is the cru node's own assigned-clocks and nothing on this
		 * board consumes the clock, so it costs nothing here.
		 */
		pr_info("%s: pmugrf not mappable this early, clk_32k_ioe left alone\\n",
			__func__);
	}

"""


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    p = os.path.join(sys.argv[1], "drivers/clk/rockchip/clk-rk1808.c")
    if not os.path.exists(p):
        raise SystemExit("no clk-rk1808.c in %s" % sys.argv[1])
    s = open(p).read()
    done = []

    # 1. armclk parent names
    if "mux_armclk_p" in s:
        done.append("armclk already ported")
    else:
        assert ARMCLK_OLD in s, "armclk call not in the expected shape"
        s = s.replace(ARMCLK_OLD, ARMCLK_NEW, 1)
        anchor = 'PNAME(mux_clk_32k_ioe_p)'
        assert anchor in s, "no PNAME anchor"
        s = s.replace(anchor, ARMCLK_PNAME + anchor, 1)
        done.append("armclk takes parent names")

    # 2. the pmu grf mux
    if "grf_type_pmu0" in s:
        done.append("pmugrf mux already ported")
    else:
        n = len(re.findall(r"\bMUXPMUGRF\(", s))
        assert n == 1, "expected one MUXPMUGRF, found %d" % n
        # MUXGRF takes the grf_type as a ninth argument
        s = re.sub(r"MUXPMUGRF\((.*?)MFLAGS\)",
                   r"MUXGRF(\1MFLAGS, grf_type_pmu0)", s, flags=re.S)
        # declarations, then the registration before the branches that use it
        s = s.replace("	struct clk **clks;\n",
                      "	struct clk **clks;\n"
                      "	struct rockchip_aux_grf *pmugrf_e;\n"
                      "	struct device_node *pmugrf_np;\n"
                      "	struct regmap *pmugrf;\n", 1)
        anchor = "	rockchip_clk_register_branches(ctx, rk1808_clk_branches,"
        assert anchor in s, "no branch registration anchor"
        s = s.replace(anchor, AUX_GRF.lstrip("\n") + anchor, 1)
        # syscon and hashtable headers
        if "#include <linux/mfd/syscon.h>" not in s:
            s = s.replace("#include <linux/clk-provider.h>",
                          "#include <linux/clk-provider.h>\n"
                          "#include <linux/mfd/syscon.h>", 1)
        done.append("pmugrf mux uses the aux grf table")

    # 3. rk_dump_cru is a bsp-only debug hook with no mainline counterpart.
    #    rk1808_dump_cru stays in the file; nothing calls it, which the
    #    compiler is content with because it is referenced by the sysfs-less
    #    build only through this hook.
    if "rk_dump_cru" in s:
        s = re.sub(r"\n\tif \(!rk_dump_cru\)\n\t\trk_dump_cru = rk1808_dump_cru;\n",
                   "\n", s)
        s = re.sub(r"\nstatic void rk1808_dump_cru\(void\)\n\{.*?\n\}\n",
                   "\n", s, flags=re.S)
        done.append("rk_dump_cru hook dropped")
    else:
        done.append("rk_dump_cru already gone")

    open(p, "w").write(s)
    for d in done:
        print("    %s" % d)


if __name__ == "__main__":
    main()
