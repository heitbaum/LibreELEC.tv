// SPDX-License-Identifier: MIT
/*
 * Board glue for the RK1808 NPU, the piece rockchip never published.
 *
 * The blob names three source files and this is the only one missing from the
 * public 6.4.6 DDK:
 *
 *     hal/os/linux/kernel/platform/rk/gc_hal_kernel_platform_1808.c
 *
 * Written against the device tree the die actually boots with, and against the
 * parameters the vendor module reports at load:
 *
 *     registerBases = 0xFFBC0000   registerSizes = 0x1000   irqs = 13
 *
 * which come from npu@ffbc0000 in rk3399pro-npu.dtsi:
 *
 *     compatible   = "rockchip,npu"
 *     reg          = <0x0 0xffbc0000 0x0 0x1000>
 *     clocks       = SCLK_NPU, ACLK_NPU, HCLK_NPU
 *     clock-names  = "sclk_npu", "aclk_npu", "hclk_npu"
 *     interrupts   = <GIC_SPI 43 IRQ_TYPE_LEVEL_HIGH>
 *     power-domains = <&power RK1808_VD_NPU>
 *
 * Deliberately minimal. The vendor module also hooks devfreq, the rockchip opp
 * tables and the system monitor, which is what pulls in rockchip_init_opp_table,
 * rockchip_ipa_power_model_init and rockchip_system_monitor_register - symbols
 * that exist in the 6.1 tree but only under CONFIG_ROCKCHIP_OPP,
 * CONFIG_ROCKCHIP_IPA and CONFIG_ROCKCHIP_SYSTEM_MONITOR. None of that is
 * needed to bring the core up: the clock runs at the rate assigned-clock-rates
 * sets in the dts, 800MHz, and dvfs can come later.
 */

#include <linux/clk.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/pm_runtime.h>

#include "gc_hal_kernel_linux.h"
#include "gc_hal_kernel_platform.h"
#include "gc_hal_version.h"

/*
 * setPower and setClock took a device index from 6.4.13 onwards, when the DDK
 * gained multi-device support. That is the only signature change in the five
 * ops this file implements across 6.4.6 to 6.4.21 - adjustParam, getPower and
 * putPower are untouched - so one file covers both eras.
 *
 * The test is on gcvVERSION_PATCH and not gcvVERSION_BUILD, because
 * build-galcore.sh rewrites the build number to claim rockchip's 351518 and
 * would defeat a test on that. No line continuation here on purpose: this file
 * is edited on a windows checkout and a backslash before CRLF is a trap.
 */
#if gcvVERSION_MAJOR == 6 && gcvVERSION_MINOR == 4 && gcvVERSION_PATCH < 13
#define RK1808_DEV_INDEX_PARAM
#else
#define RK1808_DEV_INDEX_PARAM      gctUINT32 DevIndex,
#endif

/*
 * The on-die AXI SRAM, from the vendor driver's own mapping message and
 * corroborated by AXI_SRAM_SIZE in the feature database row for this chip.
 */
#define RK1808_AXI_SRAM_BASE    0xfec10000ULL
#define RK1808_AXI_SRAM_SIZE    0x001f0000UL

struct rk1808_priv {
    struct clk *sclk;   /* sclk_npu - the core clock */
    struct clk *aclk;   /* aclk_npu - the axi master clock */
    struct clk *hclk;   /* hclk_npu - the ahb slave clock */
    bool        clocks_on;
    bool        pm_on;
};

static struct rk1808_priv rk1808;

/*
 * Everything the core needs to find the hardware. Taken from the device tree
 * rather than hardcoded, so this file does not have to change if the reg or
 * irq move.
 */
static gceSTATUS
_AdjustParam(
    IN gcsPLATFORM *Platform,
    OUT gcsMODULE_PARAMETERS *Args
    )
{
    struct platform_device *pdev = Platform->device;
    struct resource *res;
    int irq;

    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!res) {
        dev_err(&pdev->dev, "no register resource\n");
        return gcvSTATUS_OUT_OF_RESOURCES;
    }

    Args->registerBases[0] = (gctPHYS_ADDR_T)res->start;
    Args->registerSizes[0] = (gctSIZE_T)resource_size(res);

    irq = platform_get_irq(pdev, 0);
    if (irq < 0) {
        dev_err(&pdev->dev, "no irq\n");
        return gcvSTATUS_OUT_OF_RESOURCES;
    }
    Args->irqs[gcvCORE_MAJOR] = irq;

    /*
     * contiguousSize is left to the insmod argument, which is how the vendor
     * init script drives it: contiguousSize=0x400000. A base of zero lets the
     * allocator place it.
     */
    Args->contiguousBase = 0;

    /*
     * The AXI SRAM the NN engine works out of. The vendor driver maps it and
     * says so:
     *
     *     Galcore Info: MMU mapped core 0 SRAM[1] CPU base=0xfec10000
     *                   size=0x1f0000
     *
     * and 0x1f0000 is 2031616, which is exactly the AXI_SRAM_SIZE in this
     * chip's feature database row. Without it the core comes up and binds but
     * the userspace has nowhere to put weights.
     */
    Args->extSRAMBases[0] = RK1808_AXI_SRAM_BASE;
    Args->extSRAMSizes[0] = RK1808_AXI_SRAM_SIZE;

    dev_info(&pdev->dev, "npu at %pa size %#x irq %d\n",
             &res->start, (unsigned int)resource_size(res), irq);

    return gcvSTATUS_OK;
}

static gceSTATUS
_GetPower(
    IN gcsPLATFORM *Platform
    )
{
    struct device *dev = &Platform->device->dev;

    rk1808.sclk = devm_clk_get(dev, "sclk_npu");
    if (IS_ERR(rk1808.sclk)) {
        dev_err(dev, "no sclk_npu: %ld\n", PTR_ERR(rk1808.sclk));
        return gcvSTATUS_OUT_OF_RESOURCES;
    }

    rk1808.aclk = devm_clk_get(dev, "aclk_npu");
    if (IS_ERR(rk1808.aclk)) {
        dev_err(dev, "no aclk_npu: %ld\n", PTR_ERR(rk1808.aclk));
        return gcvSTATUS_OUT_OF_RESOURCES;
    }

    rk1808.hclk = devm_clk_get(dev, "hclk_npu");
    if (IS_ERR(rk1808.hclk)) {
        dev_err(dev, "no hclk_npu: %ld\n", PTR_ERR(rk1808.hclk));
        return gcvSTATUS_OUT_OF_RESOURCES;
    }

    /* the power domain is RK1808_VD_NPU, reached through runtime pm */
    pm_runtime_enable(dev);
    rk1808.pm_on = true;

    return gcvSTATUS_OK;
}

static gceSTATUS
_PutPower(
    IN gcsPLATFORM *Platform
    )
{
    struct device *dev = &Platform->device->dev;

    if (rk1808.clocks_on) {
        clk_disable_unprepare(rk1808.sclk);
        clk_disable_unprepare(rk1808.hclk);
        clk_disable_unprepare(rk1808.aclk);
        rk1808.clocks_on = false;
    }

    if (rk1808.pm_on) {
        pm_runtime_disable(dev);
        rk1808.pm_on = false;
    }

    return gcvSTATUS_OK;
}

static gceSTATUS
_SetPower(
    IN gcsPLATFORM *Platform,
    RK1808_DEV_INDEX_PARAM
    IN gceCORE GPU,
    IN gctBOOL Enable
    )
{
    struct device *dev = &Platform->device->dev;
    int ret;

    if (Enable) {
        ret = pm_runtime_get_sync(dev);
        if (ret < 0) {
            pm_runtime_put_noidle(dev);
            dev_err(dev, "cannot power up the npu domain: %d\n", ret);
            return gcvSTATUS_GENERIC_IO;
        }
    } else {
        pm_runtime_put_sync(dev);
    }

    return gcvSTATUS_OK;
}

/*
 * Order matters on the way up: the bus clocks before the core clock, so the
 * core never runs against a bus that is still gated. Reverse on the way down.
 */
static gceSTATUS
_SetClock(
    IN gcsPLATFORM *Platform,
    RK1808_DEV_INDEX_PARAM
    IN gceCORE GPU,
    IN gctBOOL Enable
    )
{
    struct device *dev = &Platform->device->dev;
    int ret;

    if (Enable && !rk1808.clocks_on) {
        ret = clk_prepare_enable(rk1808.aclk);
        if (ret)
            goto err_aclk;

        ret = clk_prepare_enable(rk1808.hclk);
        if (ret)
            goto err_hclk;

        ret = clk_prepare_enable(rk1808.sclk);
        if (ret)
            goto err_sclk;

        rk1808.clocks_on = true;
    } else if (!Enable && rk1808.clocks_on) {
        clk_disable_unprepare(rk1808.sclk);
        clk_disable_unprepare(rk1808.hclk);
        clk_disable_unprepare(rk1808.aclk);
        rk1808.clocks_on = false;
    }

    return gcvSTATUS_OK;

err_sclk:
    clk_disable_unprepare(rk1808.hclk);
err_hclk:
    clk_disable_unprepare(rk1808.aclk);
err_aclk:
    dev_err(dev, "cannot enable the npu clocks: %d\n", ret);
    return gcvSTATUS_GENERIC_IO;
}

static struct _gcsPLATFORM_OPERATIONS rk1808_ops =
{
    .adjustParam = _AdjustParam,
    .getPower    = _GetPower,
    .putPower    = _PutPower,
    .setPower    = _SetPower,
    .setClock    = _SetClock,
};

static struct _gcsPLATFORM rk1808_platform =
{
    .name = __FILE__,
    .ops  = &rk1808_ops,
};

static const struct of_device_id rk1808_dev_match[] = {
    { .compatible = "rockchip,npu" },
    { /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, rk1808_dev_match);

int gckPLATFORM_Init(struct platform_driver *pdrv,
                     struct _gcsPLATFORM **platform)
{
    pdrv->driver.of_match_table = rk1808_dev_match;

    *platform = &rk1808_platform;
    return 0;
}

int gckPLATFORM_Terminate(struct _gcsPLATFORM *platform)
{
    return 0;
}
