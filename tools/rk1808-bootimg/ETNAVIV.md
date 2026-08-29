# etnaviv on the rk1808 die

The open driver route, written up now that the parts of it that were unknown are
not. `GALCORE-SOURCE.md` establishes what the hardware is; this is what it would
take to drive it with mesa instead of galcore, what is already in hand, and what
is still a real unknown rather than a chore.

Nothing here has been run. It is a plan with the guesswork removed.

## What is settled

The core is `0x8000 / 0x7100 / 0x45080001 / 0x0 / 0x82` - VIPNanoQI, NN
generation 7 by mesa's own rule (`VIP_V7` set, `NN_XYDP0` clear). Read three
ways: the feature database row inside galcore, `VIPNANOQ_PID0X82` in the die's
`librknn_runtime.so`, and `/sys/devices/platform/ffbc0000.npu/info` on the
hardware.

`etna_hwdb.c` in mesa reads eight NPU values and three feature bits from a
database row, and every one of them exists in the 6.4.6 struct our row is
decoded against:

    NNCoreCount 10        NNMadPerCore 64        TPEngine_CoreCount 6
    VIP_SRAM_SIZE 512K    AXI_SRAM_SIZE 1984K    NN_ZRL_BITS 5
    NNInputBufferDepth 12 NNAccumBufferDepth 64
    VIP_V7 1              NN_XYDP0 0             DEC400 0

The zero run length width, which looked like the blocker, is **5 on this die and
5 on the A311D**. It reaches the encoder as `info->npu.nn_zrl_bits` and is
consumed in `etnaviv_ml_nn_v7.c` as `max_zrl_bits` - the v7 path, this die's
generation. etnaviv reads none of the seven feature *bits* that differ between
this row and the A311D's, `ZRL_7BIT` included.

## The hwdb entry

`etnaviv/gc_feature_database.h` beside this file is a complete single row
database in the shape of mesa's five vendor ones - the 6.4.6 struct verbatim
with its dual MIT/GPL Vivante header, our row, and the standard
`gcQueryFeatureDB` matcher. To wire it in:

    cp etnaviv/gc_feature_database.h \
       mesa/src/etnaviv/hwdb/rockchip/gc_feature_database.h

and add one line to `mesa/src/etnaviv/hwdb/meson.build`:

        'nxp/gc_feature_database.h',
    +   'rockchip/gc_feature_database.h',
        'st/gc_feature_database.h'

`hwdb.h.py` merges all the vendor headers into one `hwdb.h` with pycparser at
build time. The five existing inputs are from different DDK releases with
different member sets, so it has to be unioning them; if it turns out to require
them to agree, ours needs widening to another vendor's struct with the extra
members defaulted, and `featuredb-emit.py` can regenerate it.

`FormalRelease` is 0 in our row, as it is in the blob, so the matcher finds it in
its second pass, comparing `chipVersion & 0xFFF0`. That is an exact match at
0x7100 either way.

Worth being straight about provenance if this ever goes upstream: mesa's other
five databases were supplied by their vendors. This one was recovered from a
binary. The struct and its comments come from the public 6.4.6 header, which is
dual MIT/GPL, and the values are measurements of hardware - but a maintainer
will want to be told, not to find out.

## The device tree node

What the hardware is, from the vendor dts and confirmed by the platform file we
wrote for galcore:

    npu@ffbc0000
        reg            0xffbc0000  size 0x1000
        interrupts     GIC_SPI 43, IRQ_TYPE_LEVEL_HIGH
        clocks         sclk_npu (core), aclk_npu (axi master), hclk_npu (ahb slave)
        power-domains  RK1808_VD_NPU
        core clock     800MHz, set by assigned-clock-rates
        AXI SRAM       0xfec10000, size 0x1f0000  (1984K, = AXI_SRAM_SIZE)

etnaviv binds `compatible = "vivante,gc"` and names its clocks `core`, `bus`,
`reg` and `shader`. A part with no shader core uses the first three, and the
mapping follows the vendor names directly:

    etnaviv     rk1808        what it is
    core        sclk_npu      the core clock, 800MHz
    bus         aclk_npu      axi master
    reg         hclk_npu      ahb slave, register access

So the node, to be added beside the vendor `npu@ffbc0000` and enabled instead of
it, never alongside:

    npu: npu@ffbc0000 {
        compatible = "rockchip,rk1808-npu", "vivante,gc";
        reg = <0x0 0xffbc0000 0x0 0x1000>;
        interrupts = <GIC_SPI 43 IRQ_TYPE_LEVEL_HIGH>;
        clocks = <&cru SCLK_NPU>, <&cru ACLK_NPU>, <&cru HCLK_NPU>;
        clock-names = "core", "bus", "reg";
        assigned-clocks = <&cru SCLK_NPU>;
        assigned-clock-rates = <800000000>;
        power-domains = <&power RK1808_VD_NPU>;
        status = "okay";
    };

The mainline Amlogic A311D npu node is the reference to check this against - same
core family, same driver, and it is the node etnaviv's NPU support was written
for. If a `rockchip,rk1808-npu` compatible has to be added to
`etnaviv_gpu.c`'s match table, that is a two line patch; `vivante,gc` alone may
be enough.

Three things the vendor node carries that etnaviv does not want. Its
`npu-supply` and the opp table drive devfreq through
`rockchip_init_opp_table`, `rockchip_ipa_power_model_init` and
`rockchip_system_monitor_register` - none of which etnaviv calls, and none of
which are needed while the clock is pinned at 800MHz. The `vdd_npu_1` regulator
is not fitted on this board and `dts-6.1.py` already strips it. And nothing in
etnaviv consumes an external SRAM window, which is the first open question
below.

## The kernel side

`CONFIG_DRM` and `CONFIG_DRM_ETNAVIV`, on the die's own kernel. Both 6.1 and
6.12 carry etnaviv; nothing has to be forward ported for the driver itself, in
contrast to everything else this die needed.

galcore and etnaviv cannot both own the block. They claim the same registers and
each brings its own MMU, so this is one or the other per boot - which also means
the comparison at the end of this document has to be two images, not two
processes.

The identity reaches `etna_query_feature_db` from the etnaviv kernel driver's
DRM parameters - `ETNAVIV_PARAM_GPU_MODEL`, `_REVISION`, `_PRODUCT_ID`,
`_CUSTOMER_ID`, `_ECO_ID` - which the driver reads from the chip's own identity
registers. So the hwdb entry does nothing until etnaviv binds, and the first
thing to check after it binds is that those five values come back as
`0x8000 / 0x7100 / 0x45080001 / 0x82 / 0x0`.

One hazard disappears with it. `README.md` warns against reading the identity
registers with `devmem` because galcore runtime suspends the block and the read
wedges the die. With etnaviv owning the block and its own runtime pm, that read
is the driver's job and the hazard is gone.

## The userspace side

mesa built for aarch64 with the etnaviv gallium driver and Teflon, plus a
tflite runtime, running on the die's two Cortex-A35s. Which means a real rootfs
rather than the vendor buildroot image `mods.sh` edits - that image has busybox
1.27.2 and glibc 2.29 from buildroot 2018.02-rc3, and no package manager.

The transport does not change and does not need to. This is positive mode in
rockchip's own terms - the die runs the application and the host is a network
peer over the rndis link this harness already provides. Nothing of rockchip's
transport stack is involved: no `npu_transfer_proxy`, no `rknn_server`, no ntb.

## What is still unknown

Four things, in the order they are likely to bite.

**1. `NN_INTERLEVE8`.** Set on this die, `0x0` in all 46 rows of all five vendor
databases in mesa, no `etna_core_info` field, no consumer - the only reference in
the tree is the generated register define
`chipMinorFeatures11_NN_INTERLEVE8 0x00000008`. If the bit selects an eight way
interleave of weights across cores, this part - 10 NN cores and 6 TP cores, where
every other row in the database is a power of two - is exactly where it would
matter. And because nothing reads it, the failure mode is **wrong output, not a
refusal**, with no diagnostic pointing at the cause. Expect to have to compare
inference results, not just check for errors.

**2. The AXI SRAM.** galcore is given the 1984K window at 0xfec10000 through
`extSRAMBases`/`extSRAMSizes` and maps it into the core's MMU; the vendor's own
boot log shows two 256K SRAM windows mapped at hardware virtual 0x400000 and
0x440000. etnaviv has `info->npu.axi_sram_size` from the database row, but
whether it has a binding for where that window physically is, and whether the ML
path uses it, has not been checked. On the A311D the same question exists and
that part works, which is mildly encouraging.

**3. `hwdb.h.py`.** Unread. See the hwdb section - a build says immediately
whether the 733 member struct merges.

**4. No end to end result anywhere.** Not for the hwdb entry, not for the node,
not for Teflon on this core.

## The order worth doing it in

Each step is cheap and answers one question, and the first two need no hardware
change at all.

1. **Build mesa with the entry, on x86.** Confirms `hwdb.h.py` accepts the
   struct and the row survives the merge. A cross build for aarch64 does the
   same job; the point is only that it compiles.

2. **Confirm the entry is found, without the die.** `etna_query_feature_db`
   takes an `etna_core_info` - the identity can be fed in from a test harness
   rather than a live GPU. Cheapest possible check that the five tuple matches
   and that the eight NPU values come back as above.

3. **Boot the die with etnaviv instead of galcore.** The node above,
   `CONFIG_DRM_ETNAVIV`, galcore left out of the image. Success is a bound
   driver, a `/dev/dri` node, and the five identity parameters reading back
   correctly. This is also the step that proves the clocks, power domain and
   interrupt in the node are right, independently of anything ML.

4. **Teflon on the die, smallest model that exists.** First run tells you
   whether question 1 is a problem: a model that executes but produces wrong
   numbers is the `NN_INTERLEVE8` signature.

5. **Compare against galcore.** Same model, same input, the rknn stack on one
   image and Teflon on the other. This is the only way the weights question gets
   a definitive answer, and it needs the two images from step 3.

## What it buys, and what it does not

It removes the blob, and with it the two floors documented in `README.md`: the
kernel version pin, and the `CONFIG_PCI` floor that a foreign `struct device`
imposes on the trim. It also removes the userspace pairing that keeps this stack
on a 2019 buildroot.

It does not remove the transport, and it does not make the die faster. And until
step 4 runs, it does not remove the possibility that this core encodes weights in
a way no open driver has seen.
