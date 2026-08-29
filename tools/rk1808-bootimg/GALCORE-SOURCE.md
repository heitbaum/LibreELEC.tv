# galcore source: what exists, what does not

Companion to `README.md`, which states in *Why the kernel is stuck at 4.4* that
rockchip never published galcore source. This is the search behind that
statement, done properly, plus what came out of it that was not expected.

Investigated 2026-08-30 against `galcore_rk3399pro-npu.ko` and `galcore.ko` from
`rockchip-linux/rknpu`, `drivers/npu_ko/`.

Four results:

1. Rockchip's tree is not published anywhere, and the search that says so is
   recorded below rather than asserted. A second sweep including the chinese
   hosts did not change it, and turned up a stronger negative: the full RK1808
   vendor SDK is public and ships galcore only as `.ko`.
2. The *generic* 99% of that tree is published, twice, at the same DDK version -
   ST and Amlogic both ship 6.4.6 source. Only `platform/rk/` is missing.
3. Because the public 6.4.6 headers give the exact layout of
   `gcsFEATURE_DATABASE`, the chip feature rows embedded in the blob can be
   decoded field by field. That answers the *which core is this* question in
   `README.md` from the binary itself, and narrows the etnaviv question from
   "is it close to the A311D" to a 17 member diff.
4. **The missing piece was written, and the npu runs on it.** A module built
   from ST's source with our own `platform/rk/gc_hal_kernel_platform_1808.c`,
   the chip's feature row lifted out of the blob, and one integer - the build
   number the userspace insists on - runs mobilenet ssd on a 6.1 kernel with
   output bit identical to the vendor driver's. No rockchip binary is
   involved. See *Reconstructed, and it works*.

## What the blob is

    file             galcore_rk3399pro-npu.ko  ELF 64-bit LSB relocatable, aarch64
    license          Dual MIT/GPL
    description      Rockchip NPU Driver
    alias            of:N*T*Crockchip,npu*
    depends          (none)
    vermagic         4.4.185 SMP preempt mod_unload aarch64
    build id         27cc4773514c22cd14839d3d7beba8ab543624aa

`galcore.ko` and `galcore_fedora.ko` are 4.4.194; the two `rk3399pro-npu`
variants are 4.4.185. All seven modules in `drivers/npu_ko/` carry the same
driver version.

Three source paths survive in the binary, and they are the whole provenance:

    /work/projects/lion/git/vipgal_6.4.6.5/hal/os/linux/kernel/gc_hal_kernel_os.c
    /work/projects/lion/git/vipgal_6.4.6.5/hal/os/linux/kernel/allocator/default/gc_hal_kernel_allocator_gfp.c
    /work/projects/lion/git/vipgal_6.4.6.5/hal/os/linux/kernel/platform/rk/gc_hal_kernel_platform_1808.c

    $VERSION$6.4.6:351518$      ->  6.4.6.5.351518

"lion" is a rockchip internal project name; `vipgal` is VeriSilicon's VIP GAL
tree, the NPU flavour of the same gc_hal codebase that ships as the Vivante GPU
driver elsewhere. `_1808` confirms the RK3399Pro NPU is driven by the RK1808
platform glue, as expected for the same die.

### Why vermagic is not the only pin

The module imports rockchip BSP symbols that exist on no mainline kernel:

    rockchip_system_monitor_register / _unregister
    rockchip_ipa_power_model_init / rockchip_ipa_get_static_power
    rockchip_monitor_dev_high_temp_adjust / _low_temp_adjust
    rockchip_init_opp_table

So even with vermagic forced, the module needs a kernel with the rockchip system
monitor and IPA power model compiled in. This is a second floor under the one
`README.md` already documents via `struct device` and `CONFIG_PCI`.

The pcie variant additionally imports `dma_buf_*`,
`iommu_get_domain_for_dev`, `iommu_iova_to_phys`, `mutex_lock_interruptible`
and `seq_puts` - consistent with a host-side mapping path rather than an
on-die one.

### Module parameters

Useful when reading the public source alongside the blob, because the public
6.4.6 source implements every one of these:

    DDRBitWidth softReset isrPoll mmuDynamicMap sRAMLoopMode mmuPageTablePool
    sRAMRequested extSRAMSizes extSRAMBases sRAMSizes sRAMBases allMapInOne
    smallBatch enableNN registerAPB userClusterMasks type chipIDs registerSizes
    registerBases irqs mmu showArgs stuckDump recovery physSize baseAddress
    powerManagement compression fastClear

`showArgs=1` dumps them all at load. `enableNN` is the NN core mask,
`sRAMBases`/`sRAMSizes` the AXI SRAM wiring - see *AXI\_SRAM\_SIZE* below.

## Is the source published anywhere

No. Searched, not assumed:

- grep.app code search: `gc_hal_kernel_platform_1808` -> 0 hits. `351518` ->
  only unrelated repositories. `gcvVERSION_BUILD` -> only NXP's
  `kernel-module-imx-gpu-viv`.
- No public gc_hal tree anywhere contains a `platform/rk/` directory. The
  complete set of vendor glue directories across every public tree found is
  `default`, `st`, `freescale`, `amlogic`, `allwinner`, `hyxt`.
- `rockchip-linux/kernel`: file lists of `develop-4.4`, `develop-4.19` and
  `develop-5.10` contain zero `gc_hal*` or `galcore*` files. `drivers/rknpu`
  on 4.19 and 5.10 is source, but it is the later RKNN IP, not this driver.
- A full RV1126 rockchip SDK dump - `OpenHD/OpenHD-RV1126-OS`, 41,124 tracked
  files - has zero matches for `gc_hal` or `galcore` in source form. That one
  needs a caveat: its `external/` is an unpopulated gitlink (`160000 commit
  7c35ffe7`, with no `.gitmodules`), so the subtree that would hold the driver
  is absent rather than searched. The populated SDK unpacks below are the real
  evidence. What this dump does settle is the packaging: its
  `buildroot/package/rockchip/rknpu/rknpu.mk` compiles nothing; it selects a
  prebuilt and installs it:

        NPU_KO_FILE = galcore_rk3399pro-npu-pcie.ko
        $(INSTALL) -D -m 0644 $(@D)/drivers/npu_ko/$(NPU_KO_FILE) \
            $(TARGET_DIR)/lib/modules/galcore.ko

- `repo.rock-chips.com/rk1808/` publishes docs, models, the rknn api and host
  side USB drivers. No NPU kernel source.
- `airockchip/RK3399Pro_npu` (the source of our 2022 image): no kernel source.

Rockchip has never answered on it either way. The closest public request is
`rockchip-linux/rknpu` issue #18, "Kernel 4.19 support (vermagic: 4.19.111
aarch64)", opened October 2021, still open with no reply - and note it asks
rockchip to *build* a module rather than to release source, which is what people
do when no source is on offer. No GPL source request appears anywhere public,
despite the module declaring `Dual MIT/GPL`. The `LICENSE` in `rknpu` is a
rockchip 2-clause BSD covering the userspace headers and samples; it says nothing
about the kernel module.

### Second sweep, chinese hosts included

The gitee gap this section originally recorded has since been closed, and the
answer did not change. Repeated 2026-08-30 across gitee, baidu, csdn, cnblogs,
software heritage, t.rock-chips.com, redmine.rock-chips.com, wiki.t-firefly.com
and ebaina.com:

- no `gc_hal_kernel_platform_1808.c`, `_1806.c`, `_puma.c`, `_rv1126.c` or any
  `platform/rk/` directory, in any gc_hal tree, at any version.
- `gitee.com/caesar-wang/rknpu` and `gitee.com/zhang2015quan/rknpu` are what
  they looked like: the same seven prebuilt `.ko` and nothing else. So are the
  gitlab mirrors - bearkey, firefly-linux, jc-rk3399-jd4, rk356x-sdk,
  rpdzkj-rockchip-linux, zhumingliang1209.
- the entire commit history of `rockchip-linux/rknpu`, `airockchip/rknpu`,
  `airockchip/RK3399Pro_npu` and `airockchip/rknpu_ddk` is blob updates. No
  source was committed and later removed.

The strongest negative came out of that sweep. **The full RK1808 vendor SDK is
public** - three complete unpacks on gitlab, `leechee/rk1808-linux-v10`,
`rpdzkj2018/rk1808-linux-v10` and `yview-develop/ai-rk1808-linux-v10` - and it
ships galcore only as `.ko`. `kernel/drivers/` has no npu directory,
`kernel/drivers/gpu/` is `arm drm host1x ipu-v3 rogue rogue_m vga` with arm
being mali only, and `external/rknpu/drivers/npu_ko/` holds the same seven
binaries. Rockchip's own public build process never had the source either.
Toybrick's `rockchip-toybrick/kernel` is the same.

The repo manifest says it from the other end. `rk1808_linux.xml` - the public
RK1808 SDK manifest, mirrored at `gitee.com/ncnnnnn/rockchip-linux-manifests` -
lists **52 projects** against `github.com/rockchip-linux/`, and the npu related
ones are `external/rknn-toolkit`, `external/rknn_demo` and
`external/tensorflow`. There is **no `rknpu` project, and no galcore anywhere in
it**. So the `external/rknpu` that `rknpu.mk` installs from is never populated by
`repo sync`: in rockchip's own build description the npu driver is a drop-in
rather than a repository.

Two details in the same file corroborate other readings here. Its toolchain
project is
`prebuilts/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu`,
which is the exact toolchain string left in the 2019 galcore binary's build
paths - so the blobs were built inside this SDK, with this compiler. And
`buildroot` is pinned at `rockchip/2018.02-rc3`, which is the vintage `README.md`
reports for both vendor rootfs images, 2019 and 2022 alike.

Search coverage was uneven and worth recording so the negative is not read as
stronger than it is: baidu was unreachable, sourcegraph returned zero for a control query and reported a
backend down, searchcode is retired, and github's own code search index is
demonstrably incomplete - `filename:gc_hal_version.h` misses a repository that
provably contains that file. The negative rests on the vendor SDK contents,
which is direct evidence, rather than on search exhaustiveness.

gitee's code search has since been run by hand, past the `安全验证码` gate that
blocks automation: `gc_hal_kernel_platform_1808`, `vipgal` and
`platform/rk/gc_hal_kernel_platform` each return **0 results**. Its
`/api/v5/search/repositories` endpoint is not a substitute - unauthenticated it
answers `[]` to every query including a control search for `linux`, so an empty
result from the api means nothing at all.

Two near misses, both useful rather than decisive:

- `github.com/kiramint/Avaota-linux`, `bsp/drivers/npu/aw_nna_galcore/` - a
  complete galcore tree at 6.4.15.3.690884 with
  `os/platform/allwinner/gc_hal_kernel_platform_allwinner.c`. Wrong vendor and
  nine patch levels newer, but a second worked example of platform glue
  alongside amlogic's.
- `gitee.com/databuser/gpu_vivante` - a full vivante GAL tree, but
  `gc_hal_version.h` reads 4.6.6 build 1381, dated March 2012, predating the
  `platform/` abstraction entirely. A decoy: "4.6.6" reads like "6.4.6" at a
  glance.

## The same DDK is published, twice

Both verified by reading `hal/kernel/inc/gc_hal_version.h` out of the tree, not
from a description of it:

    ST        gcnano-driver-6.4.6.tar.xz      6.4.6.342038         build -9,480
    Amlogic   buildroot-ddk-6.4-release       6.4.6.2.5.3.2/345497 build -6,021
    ours      galcore_rk3399pro-npu.ko        6.4.6.5.351518       -

    git clone --depth 1 -b gcnano-6.4.6-binaries \
        https://github.com/STMicroelectronics/gcnano-binaries
    tar xf gcnano-binaries/gcnano-driver-6.4.6.tar.xz

    git clone --depth 1 -b buildroot-ddk-6.4-release \
        https://github.com/yan-wyb/npu-driver-amlogic-for-test

Both are forked to `heitbaum/gcnano-binaries` (200 MiB, all branches - the ST
repo carries every version from 6.2.4 to 6.4.21) and
`heitbaum/npu-driver-amlogic-for-test` (31 MiB), so the upstreams above are
provenance rather than the working copies. The ST fork is the more valuable of
the two to hold: it is the only publisher that keeps every DDK release, which is
what makes the 6.4.6 / 6.4.7 bracket around our build number possible.

Despite the repository name, ST publishes the kernel driver as **source**; only
the userland is binary. Older branches ship it as `gcnano-driver-<ver>.tar.xz`,
6.4.13 and newer unpacked as `gcnano-driver-stm32mp/`. The OE recipe
`gcnano-driver-stm32mp` just fetches that repo.

`khadas/android_vendor_amlogic_npu` at commit `de38907` is the same build
number, 345497, as an earlier sub-release (`6.4.6.2.2.2.1`).

Nothing public sits at 6.4.6 with a build number above ours. ST 6.4.7 is
365873, so 6.4.6.5 is bracketed within about 24k build numbers by two ST
releases.

The NXP lineage is the wrong place to look: it skips 6.4.6 entirely.

    nxp-auto-linux/galcore master              6.4.0.p2.234062
    coral imx-gpu-viv-ko master                6.4.2.256507
    nxp-imx/linux-imx lf-5.10.y                6.4.3.p2.336687
    nxp-imx/linux-imx lf-5.15.y                6.4.3.p4.398061
    nxp-imx/linux-imx lf-6.1.y                 6.4.11.p2.711242
    nxp-imx/linux-imx lf-6.6.y                 6.4.11.p2.745085
    nxp-imx/linux-imx lf-6.12.y                6.4.11.p4.1190909
    Freescale/kernel-module-imx-gpu-viv master 6.4.11.p3.1049711

Others found, for the record:

    khadas/linux khadas-vims-4.9.y  drivers/amlogic/npu/   6.4.8.7.1.1.1  415784
    khadas/linux khadas-vims-5.4.y and 5.15.y              no gc_hal at all
    orangepi linux sun60iw2 (A733)  bsp/drivers/npu/       6.4.18.6.904649
    orangepi linux sun55iw3 (A527)  bsp/drivers/npu/       6.4.15.3.690884
    ST branches: 6.2.4.p3 / p4, 6.4.1, 6.4.3, 6.4.6, 6.4.7, 6.4.9,
                 6.4.13, 6.4.15, 6.4.19, 6.4.21

## How much is actually missing

Every source path the blob names, checked against the ST 6.4.6 tree:

    YES  hal/os/linux/kernel/gc_hal_kernel_os.c
    YES  hal/os/linux/kernel/allocator/default/gc_hal_kernel_allocator_gfp.c
    NO   hal/os/linux/kernel/platform/rk/gc_hal_kernel_platform_1808.c

So the missing surface is one platform file and its `.config`. For scale, the
analogues:

    st/gc_hal_kernel_platform_st.c            497 lines
    amlogic/gc_hal_kernel_platform_amlogic.c  649
    amlogic/gc_hal_kernel_platform_c308x.c    511
    amlogic/gc_hal_kernel_platform_pico.c     453
    amlogic/gc_hal_kernel_platform_vim3.c     179

The amlogic ones are the better template: they are an NPU (VIPNano) at this
exact DDK, so they carry the NN core and SRAM paths, where ST's is a GCNano GPU.

What an `rk/` file would have to do, read off the blob's imports and parameters:
clocks, resets and power domain for `rockchip,npu`; the AXI SRAM base and size;
the IRQ; and the OPP/devfreq hookup that pulls in `rockchip_init_opp_table`,
`rockchip_system_monitor_register` and `rockchip_ipa_power_model_init`.

### What a source build would buy, and what it would not

It would buy the two floors in `README.md`. A galcore built from source against
our own kernel is not compiled against a foreign `struct device`, so
`CONFIG_PCI` stops being load bearing and the trim can go further; and vermagic
stops mattering because we build it.

It would not buy a kernel newer than 4.4 on its own. The BSP symbols above still
have to exist, which means either staying on rockchip's tree or porting the
system monitor and IPA power model forward with it. And it would not buy
anything on the userspace side: `librknn_runtime.so`, `libOpenVX.so` and
`libVSC.so` on the die remain binary and remain paired to the driver version,
which is the practical reason a hand built galcore is less useful than it
sounds. That pairing is why the 2019 and 2022 images both carry
6.4.6.5.351518 despite three years between them.

The honest summary: a source build is a 6.4.6 tree plus a few hundred lines of
platform glue plus a build against the BSP kernel, and the payoff is a better
trim, not a newer kernel and not an open stack. The route that removes the blob
is still etnaviv.

## Reconstructed, and it works

Done, 2026-08-30. `/dev/galcore` on a 6.1 kernel, bound to `ffbc0000.npu`, from
a module built out of ST's public source with no rockchip blob in it:

    crw------- root root 199, 0 /dev/galcore
    galcore 483328 0
    drivers/galcore/ffbc0000.npu -> devices/platform/ffbc0000.npu

    rknn_server 1.7.5 stable, NPU Transfer 2.1.0 on the die,
    host proxy 2.1.0 reading devid = c509a098222fdbaa

Four pieces, all in this directory and all smaller than expected.

**The kernel compat layer was three lines**, not the port that 5.11 against 6.1
suggested. `build-galcore.sh` applies them:

    #include <stdarg.h>  ->  <linux/stdarg.h>    5.15 removed the host header
    -Wno-error= x3                               gcc 15, 9 vendor style sites
    MODULE_IMPORT_NS(DMA_BUF)                    5.16 gave dma_buf_* a namespace

plus `make modules_prepare && make modules` on the kernel tree first, for
`scripts/module.lds` and `Module.symvers`. No kernel api porting at all.

**The platform file**, `platform/rk/gc_hal_kernel_platform_1808.c`, is the piece
this document was written about. Register base, size and irq come from the
device tree rather than being hardcoded; three clocks; runtime pm for the power
domain. It deliberately does not do devfreq, which is what pulls in
`rockchip_init_opp_table`, `rockchip_ipa_power_model_init` and
`rockchip_system_monitor_register` - all three exist in the 6.1 tree under
`CONFIG_ROCKCHIP_OPP`, `CONFIG_ROCKCHIP_IPA` and
`CONFIG_ROCKCHIP_SYSTEM_MONITOR`, so the *Why vermagic is not the only pin*
floor above is real but not a wall. None of it is needed to bring the core up.
Modelled on amlogic's `gc_hal_kernel_platform_vim3.c`; it compiled first try.

**The feature database gap closed itself.** With the platform file in place
galcore came up, read the hardware and stopped:

    [galcore]: Feature database is not found, chipModel=0x8000,
               chipRevision=0x7100, productID=0x45080001, ecoID=0x0,
               customerID=0x82

The public headers describe every chip ST and Amlogic ship and none that
rockchip do - but the row exists inside rockchip's blob, which is what the rest
of this document is about. `featuredb.py` decodes it; `featuredb-emit.py`
writes it back out as C in the header's own field order and splices it into
`gChipInfo[]`. That is the whole fix.

**One device tree change was needed**, and it was already predicted here: this
board has no syr827 at i2c 0x40. On 4.4 the failed probe was only noisy; on 6.1
device links make it a hard dependency and the npu never probes at all -
`ffbc0000.npu platform: supplier 1-0040 not ready`. `dts-6.1.py` removes it.

**And one config symbol.** The host proxy first reported
`devid = 0000000000000000` against the vendor stack's `c509a098222fdbaa`. The
proxy identifies the die by its usb serial, `S50usbdevice` copies that out of
`/proc/cpuinfo`, and that field is populated from the efuse by
`rockchip-cpuinfo` - present in the 6.1 tree, not enabled. With
`CONFIG_ROCKCHIP_CPUINFO` the id matches the vendor stack exactly.

### It runs

The whole stack works, and the inference output is bit identical to the vendor
driver's:

                       output[0] first values          output[1] first values
    vendor 4.4    -0.2093 -0.9768 -4.2559 -4.6048   3.1013 -5.1239 -9.7084 -7.8207
    ours   6.1    -0.2093 -0.9768 -4.2559 -4.6048   3.1013 -5.1239 -9.7084 -7.8207

`rknn-probe.c` here is the test: it drives librknn_api on the host, the
transfer proxy, usb, rknn_server on the die, galcore and the hardware, with
mobilenet ssd. It passes on both stacks, which is what makes the comparison
worth anything.

### What was actually wrong: the reported build number

It took a core dump to find, and the answer was one integer.

The first symptom was `rknn_init` failing with
`recv(MsgLoadAck) fail, -9(ERROR_PIPE)` because rknn_server segfaulted on the
die. Enabling core dumps in the image and reading the core with gdb gave:

    #0  vnn_CreateRKNN      str w0, [x22, #40]   with x22 = 0
    #1  BuildGraph          librknn_runtime.so
    #2  RKNNRuntime::init   librknn_plugin.so

x22 is the return of the call immediately before, `vsi_nn_CreateContext`, and
the string being copied into that NULL struct is `"VIPNANOQ_PID0X82"` - this
chip. So the runtime identified the hardware correctly, then wrote the name
into a context that was never created, without checking.

Instrumenting our own driver to log any failing ioctl showed **none**. The
driver was never asked for anything it refused, so the decision was made in
userspace on a value it read back.

That value is the driver's build number. galcore reports
`gcvVERSION_BUILD` through `gcvHAL_VERSION`; ST's source says 342038, the
userspace on the die shipped against 351518, and it will not proceed unless
they match. Setting it to 351518 makes everything work.

`build-galcore.sh` does that as `VERSION_CLAIM`, defaulting to 351518. It is a
compatibility claim rather than a real version - the code is ST's 342038 - and
it is confined to one define. That it produces bit identical output is the
evidence that the two are compatible in fact, not merely in the number.

### Where the earlier readings were wrong

Three, worth keeping because each looked convincing:

- *"Not the version handshake."* Wrong, and it was the answer. These lines:

      [     1] HAL user version 6.4.6.5.351518
      [     2] HAL kernel version 6.4.6.5.351518

  are both printed by libGAL from its own compiled in version, which is true
  and is why they did not change when the driver did. But a check exists
  elsewhere, and it is on the number the driver reports.
- *"6.4.7 fails the same way, so it is not the build number."* It failed for
  the same reason: 365873 is no closer to 351518 than 342038 is. The test was
  right and the conclusion drawn from it was not.
- *"The 6.4.6.5 userspace will not run against a 6.4.6.342038 driver."* Only
  because of the number. The ABI is compatible.

The general shape of the mistake: three parameter level guesses in a row
missed, and the fourth answer came from a backtrace. The evidence was cheap to
get and should have been got first.

### The identity, confirmed a third way

This driver reads it off the silicon at probe:

    chipModel 0x8000  chipRevision 0x7100  productID 0x45080001
    ecoID 0x0  customerID 0x82

`0x82` is `VIPNANOQ_PID0X82`, the one vivante product the 2019
`librknn_runtime.so` names. Together with the sysfs read in `README.md` and the
row decoded out of the blob below, the core is a VIPNanoQ beyond argument.

## The feature database, decoded

This is the part that turned out to be worth the search.

`README.md` notes rockchip's tree has no `gc_feature_database.h`. Both public
6.4.6 trees have it - and the struct it defines is what the blob's embedded chip
rows are instances of.

Parsed from both public headers:

    gcsFEATURE_DATABASE   733 members: 91 gctUINT32, 1 const char *, 641 bitfields
    member list           identical between ST 6.4.6.342038 and AML 6.4.6.2.5.3.2
    computed size         91*4 + 8 + ceil(641/32)*4  =  364 + 8 + 84  =  456 bytes

Both database entries in the blob are then locatable by their identity words,
and the distance between them settles the layout question:

    galcore_rk3399pro-npu.ko
      entry 1 at 0x3b850   0x8000 0x7100 0x45080001 0x0
      entry 2 at 0x3ba18   0x8000 0x8003 0x05080009 0x4000000
      delta                456 bytes  ==  the size computed from the public header

An independent check that rockchip's 6.4.6.5 uses the same struct as the
published 6.4.6 trees. Decoding with the public field order therefore gives
named values, not guesses.

### Entry 1 - this die

    chipID              0x8000        chipVersion   0x7100
    productID           0x45080001    ecoID         0x0
    customerID          0x82          patchVersion  0        formalRelease 0

    NNCoreCount         10            NNMadPerCore          64
    NNCoreCount_INT8    10            NN_ACTIVE_CORE_COUNT  10
    NNCoreCount_INT16   2             NNCoreCount_FLOAT16   2
    TPEngine_CoreCount  6             CoreCount             1
    VIP_SRAM_SIZE       524288        AXI_SRAM_SIZE         2031616
    NNInputBufferDepth  12            NNAccumBufferDepth    64
    ThreadCount         256           InstructionCount      512
    NumberOfConstants   320           TempRegisters         64

    VIP_V7  1    NN_XYDP0  0    NN_ZDP3  1    NN_ZDP6  0
    TP_ENGINE 1  NN_INT16_ALU 1  NN_FP16_ALU 0  DEC400 0  ZRL_8BIT 0

`customerID 0x82` is the confirmation. `README.md` identifies this entry as the
die by working from the userspace - `librknn_runtime.so` in the 2019 image knows
exactly one vivante product, `VIPNANOQ_PID0X82`. The blob's own row carries
`0x82` in the customerID field, and entry 2 carries `0xb5`, matching
`VIP8000NANOSI_PID0XB5` in the 2022 image. Two independent artifacts, same
answer, and now it is read out of the driver rather than inferred.

The same identifier names the DDK build config. `aml_build.sh` in amlogic's
6.4.6 drop sets `BUILD_OPTION_GPU_CONFIG="vipnanoqi_pid0x7d"`, and `0x7d` is
the customerID in its own `0x8000`/`0x7004` feature row - so the config name is
keyed on customerID, and rockchip's will have been `vipnanoqi_pid0x82`. The
`VIPNANOQ_PID0X82` string in `librknn_runtime.so` and the DDK's build config
are the same identifier, reached from opposite ends. (Inferred for rockchip;
read directly for amlogic.) Its other build options, as a reference for ours:
`NO_DMA_COHERENT=1`, `USE_PLATFORM_DRIVER=1`, `USE_VDK=1`, `USE_VXC_BINARY=0`,
`gcdSTATIC_LINK=0`.

`AXI_SRAM_SIZE 2031616` is 1984 KiB - the die's AXI SRAM, which is what the
`sRAMBases`/`sRAMSizes` module parameters wire up.

Applying mesa's own rule from `etnaviv_screen.c` to these bits:

    NN_XYDP0 = 0, VIP_V7 = 1   ->   NN generation 7

which is what `README.md` concluded from `libOpenVX.so` printing a
`VIP7Version`. Confirmed from the feature bits mesa itself keys on.

### Entry 2 - the newer part, for contrast

    chipID 0x8000  chipVersion 0x8003  productID 0x05080009  ecoID 0x4000000
    customerID 0xb5
    NNCoreCount 4   TPEngine_CoreCount 2   VIP_SRAM_SIZE 262144
    AXI_SRAM_SIZE 0   NN_XYDP0 1   NNCoreCount_FLOAT16 0

### Against the A311D

The Amlogic header carries `0x8000 rev 0x7120 product 0x45080009` - the exact
part `README.md` calls two revisions away and etnaviv's best supported NPU
target. Diffing the decoded blob row against the published row, member by
member across all 733:

    17 members differ, of 733

    chipVersion                        rk 0x7100      a311d 0x7120
    productID                          rk 0x45080001  a311d 0x45080009
    customerID                         rk 0x82        a311d 0x88

    NNCoreCount                        rk 10          a311d 8
    NN_ACTIVE_CORE_COUNT               rk 10          a311d 8
    NNCoreCount_INT8                   rk 10          a311d 8
    NNCoreCount_INT16                  rk 2           a311d 8
    NNCoreCount_FLOAT16                rk 2           a311d 0
    TPEngine_CoreCount                 rk 6           a311d 4
    AXI_SRAM_SIZE                      rk 2031616     a311d 1048576

    NN_XYDP6                           rk 0           a311d 1
    NN_CACHELINE_MODE_PERF_FIX         rk 1           a311d 0
    NN_ZXDP3_KERNEL_READ_CONFLICT_FIX  rk 0           a311d 1
    NN_ASYNC_COPY_PERF_FIX             rk 0           a311d 1
    NN_JD_DIRECT_MODE_FIX              rk 1           a311d 0
    NN_INTERLEVE8                      rk 1           a311d 0
    ZRL_7BIT                           rk 1           a311d 0

Three of those are identity. Seven are sizes - more NN cores, more TP cores,
twice the AXI SRAM, fewer INT16 lanes. Seven are feature bits.

**Answered, and the other way round: `NN_INTERLEVE8` is the one that matters
and `ZRL_7BIT` is not.** Checked against mesa 26.2.1.

etnaviv never reads `ZRL_7BIT` or `ZRL_8BIT`. Its zero run length handling comes
from the value field beside them:

    hwdb/etna_hwdb.c:138          info->npu.nn_zrl_bits = db->NN_ZRL_BITS;
    common/etna_core_info.h:99    unsigned nn_zrl_bits;  /* Number of bits for
                                  zero run-length compression */
    gallium/drivers/etnaviv/etnaviv_ml_nn_v7.c:466
                                  unsigned max_zrl_bits =
                                      etna_ml_get_core_info(screen)->nn_zrl_bits;

`NN_ZRL_BITS` is **5 on this die and 5 on the A311D** - it is absent from the 17
member diff because it does not differ. The one ZRL parameter the encoder
consumes is identical on both parts, and it arrives in the `_v7` path, which is
this die's generation. Bit and width move independently anyway: mesa's amlogic
row with `ZRL_7BIT=1` (`0x7131`, customer `0x99`) carries `NN_ZRL_BITS=8` and
`ZRL_8BIT=1` too.

That also disposes of reading `ZRL_7BIT=1` as ours alone. Four rows across
mesa's five hwdb databases set it, one of them the part ST upstreamed
themselves:

    st       0x8000 / 0x6205 / 0x80003    cust 0x15   (eco 0x0 and 0x1)
    st       0x7000 / 0x6204 / 0x70007    cust 0x13
    amlogic  0x8000 / 0x7131 / 0x8000001  cust 0x99

`NN_INTERLEVE8` is the one that is genuinely ours. It is `0x0` in all 46 rows of
all five vendor databases; it has no `etna_core_info` field; and nothing outside
the vendor headers consumes it - the only other reference in the tree is the
register define `chipMinorFeatures11_NN_INTERLEVE8 0x00000008` in the generated
`hw/common.xml.h`. Next to it sits the other oddity of this row: `NNCoreCount`
10 and `TPEngine_CoreCount` 6, where the A311D is 8 and 4 and every other part
in the database is a power of two. If the bit selects an eight way interleave of
weights across cores, a ten core part is where that would have to differ. Two
facts beside each other, not a claim.

So the remaining shape. The hwdb lookup is the full five tuple -
`gcQueryFeatureDB(model, revision, product_id, eco_id, customer_id)` - making
ours `(0x8000, 0x7100, 0x45080001, 0x0, 0x82)`, and that `0x82` is the same
identifier as the DDK's `vipnanoqi_pid0x82` config and `VIPNANOQ_PID0X82` in
`librknn_runtime.so`. Every field such an entry needs is decoded already.
Whether it then produces correct weights is one bit's worth of unknown, against
an encoder that has now been shown to parameterise rather than hardcode.

## What 351518 has that 342038 does not

The section above left one thing open: the userspace wants build 351518, the
self built driver claims it, and the inference comes out bit identical - but
identical output on one model is evidence, not proof that nothing else differs.
Comparing the two modules by defined function closes it.

Neither module is stripped of anything useful; galcore keeps its static
function names in `.symtab`, so the sets compare directly. gcc clones functions
for specialised call sites and marks the clones `.isra`, `.constprop`, `.part`.
Those are artefacts of the compiler, not of the source, and are folded away
before comparing - without that step the comparison is noise.

    vendor  galcore.ko  483096 bytes   720 functions
    ours    galcore.ko  666040 bytes   764 functions
                                       689 in common

Thirty one functions are in the vendor blob and not in ours. Most of them are
not features.

**sysfs against debugfs.** Sixteen of the thirty one are sysfs handlers:

    info_show  version_show  database_show  database64x_show  clients_show
    idle_show  load_show  meminfo_show  vidmem_show  vidmem_store
    vidmem64x_show  vidmem64x_store  clk_show  clk_store
    dump_trigger_show  dump_trigger_store

Ours has every one of them, under another name and on another filesystem:
twelve `gc_*_show_debugfs` readers - `gc_info_show_debugfs`,
`gc_version_show_debugfs`, `gc_db_show_debugfs`, `gc_clients_show_debugfs` and
the rest - the writers as `gc_clk_write`, `gc_vidmem_write` and
`gc_dump_trigger_write`, and `debugfs_printf` where the vendor has `sys_printf`.
The DDK builds one or the other. Same counters, different mount point - which is
why the earlier reading of these as vendor additions was wrong.

**The DRM node.** The vendor blob has `setup_drm_pages`, `_dmabuf_kmap` and
`_dmabuf_kunmap` and nothing else of DRM. Ours has the whole GEM interface -
`viv_drm_probe`, `viv_gem_prime_export`, fourteen `viv_ioctl_gem_*`, the fence
timeline - because our kernel keeps `CONFIG_DRM`. On this axis ours is the
superset, not the subset.

**Naming under inlining.** The vendor has `_ProgramTPOutput`, ours has
`_ProgramNNOutput`. Both have `_ProgramNNInput` and `_ProgramTPInput`, and in
both modules those two resolve to *the same address* - identical code, folded by
the compiler. Which name survives is decided by which caller gcc kept, not by
what the driver does.

The MCFE split differs the same way: the vendor has `_CheckFlushMcfeMMU` and
`_GetFreeMcfeSemaNum`, ours has `_DestroyMCFE`, `_GetNextMcfeSemaId` and
`_WaitPendingMcfeSema`. Both modules implement MCFE; the helpers gcc left
standing are not the same ones.

This is also where the first attempt at this comparison went wrong. gcc's clone
suffixes stack - `_ProgramTPOutput.isra.7.constprop.25` is a real symbol - so
stripping one suffix leaves `_ProgramTPOutput.isra.7`, which then reads as a
difference against the other side's `_ProgramTPOutput.constprop.0`. Folding
until the name stops changing moves four functions from "different" to
"common": `_DumpFEStack`, `_DumpLinkStack`, `_ExternalCacheOperation` and
`_ShowVideoMemoryOldFormat`. Without it the comparison reads 685 common with 35
and 79 either side, instead of 689 with 31 and 75.

What is left after those three groups is the whole of the real difference:

    gckDevfreq_Init    gckDevfreq_term    gckDevfreq_target
    gckDevfreq_get_cur_freq    gckDevfreq_get_dev_status
    gck_get_static_power    _Power_off_delay_work

devfreq. Frequency scaling, the static power model, and the delayed power off
that goes with it. Which is exactly what `gc_hal_kernel_platform_1808.c` says
it left out, and for the reason stated there: the core runs at the rate the
device tree assigns, 800MHz, and dvfs can come later. The clock never changes
on our driver, so nothing asks for these.

Nothing in the NN path differs. Nothing in the MMU path differs. The two
modules implement the same 689 functions, and the seven that only the vendor
has are all power management.

The size gap is not features either. 483096 against 666040 is gcc 6.3 against
gcc 15 on the same source - different inlining, larger alignment padding, and
in our case the DRM node compiled in as well.

## The lineage, 6.4.6 to 6.4.21

Rockchip's blob sits at 6.4.6.5. Ours is built from the public 6.4.6. Both are
old: VeriSilicon's gc_hal has kept moving, and Allwinner ship a 6.4.15 in their
public BSP. Whether any of that is worth chasing depends on what actually
changed, so this compares six releases.

    release             build      source
    6.4.6               342038     ST, gcnano-driver 6.4.6
    6.4.6.5             351518     rockchip, blob only - no source anywhere
    6.4.7               365873     ST, gcnano-driver 6.4.7
    6.4.13              608341     ST, gcnano-driver-stm32mp
    6.4.15              690884     allwinner, Avaota-linux bsp/drivers/npu
    6.4.19              952875     ST, gcnano-driver-stm32mp
    6.4.21             1058597     ST, gcnano-driver-stm32mp

The three stm32mp trees came out of the same untracked directory, so they were
checked against `gcvVERSION_BUILD` before being trusted - 608341, 952875 and
1058597 respectively. They are distinct.

One thing to expect when repeating this: a 6.4.6 tree that has been built here
reports 351518, not 342038. `build-galcore.sh` writes `VERSION_CLAIM` into
`gc_hal_version.h`, which is the whole point of it - the number in the table
above is pristine upstream 6.4.6. Reading 351518 back out of the tree is
confirmation the claim landed, not a mislabelled checkout.

### Line counts mislead

    release        mmu.c   hardware.c   command.c   video_memory.c
    6.4.6           4670        17157        4938             4846
    6.4.7           4593        17346        5018             4963
    6.4.13          4484        11404        4233             5045
    6.4.15 aw       4542        11676        4267             5136
    6.4.19          4671        12155        4334             5285
    6.4.21          4703        12187        4627             5297

`hardware.c` appears to lose six thousand lines at 6.4.13, and a raw diff calls
it eighteen thousand changed lines - a rewrite, on the face of it. It is not.
6.4.13 restyled the whole DDK from Allman braces to K&R, dropped the
`IN`/`OUT`/`OPTIONAL` parameter annotations, rejoined multi-line prototypes onto
single lines, and moved the mmu declarations - `gceMMU_TYPE`,
`gcsMMU_STLB_CHUNK`, `gcsFreeSpaceNode`, `gcdFLAT_MAPPING_MODE` - out into a new
`gc_hal_kernel_mmu.h`. Every signature and every wrapped statement differs while
the code does the same thing.

Normalising whitespace does not fix this either; it still reports ~50% churn,
because the line boundaries themselves moved. Token counts tell the truth, and
they go *up* through the same transition:

    release        mmu.c   hardware.c   command.c   video_memory.c
    6.4.6          19853       173906       16198            18839
    6.4.7          19617       175261       16550            19404
    6.4.13         24309       188773       18066            23373
    6.4.15 aw      24686       194862       18229            23829
    6.4.19         25333       206933       18671            24585
    6.4.21         25411       207098       20474            24634

The MMU grew 28% in tokens while shrinking in lines.

### Where the one real break is

Similarity over 7-token shingles, which is insensitive to the reformatting:

    transition              mmu.c   hardware.c   command.c   video_memory.c
    6.4.6  -> 6.4.7         95.3%        97.3%       94.4%            89.0%
    6.4.7  -> 6.4.13        50.7%        70.1%       80.8%            57.4%
    6.4.13 -> 6.4.15 aw     91.0%        95.3%       97.5%            95.6%
    6.4.15 -> 6.4.19        96.8%        94.2%       93.8%            94.0%
    6.4.19 -> 6.4.21        98.8%        99.3%       90.7%            99.3%

There is exactly one generational boundary, between 6.4.7 and 6.4.13. Everything
before it is one driver and everything after it is another. Measured against the
release we build from:

    6.4.6 -> 6.4.7          95.3%        97.3%       94.4%            89.0%
    6.4.6 -> 6.4.13         49.4%        68.9%       76.6%            53.6%
    6.4.6 -> 6.4.15 aw      45.9%        66.7%       75.1%            52.2%
    6.4.6 -> 6.4.19         45.1%        64.0%       71.4%            49.9%
    6.4.6 -> 6.4.21         45.1%        63.8%       65.2%            49.8%

Note that 6.4.13 through 6.4.21 are all ~45% from 6.4.6 in the MMU. The distance
is the boundary, not the accumulation - once across it, four more releases add
almost nothing by comparison.

This also settles, from a second direction, why claiming 365873 changed nothing
for us. 6.4.7 is 95-97% the same driver as 6.4.6. It was never going to behave
differently; only the number it reports differs.

### The interfaces our platform file depends on

Across all six releases the MMU loses exactly one function, `_GetPageTablePool`,
and gains none. `gckMMU_SetupSRAM` keeps its signature unchanged in every one:

    gckMMU_SetupSRAM(gckMMU Mmu, gckHARDWARE Hardware, gckDEVICE Device)

`extSRAMBases` and `extSRAMSizes` survive throughout, still 60 to 67 references.
At 6.4.13 the module parameters moved out of `gc_hal_kernel_driver.c` into a new
`gc_hal_kernel_parameter.h` - same parameters, new home, which a grep restricted
to `*.c` will miss and report as "parameters removed". The newer releases read
the value through `gckOS_QueryOption(os, "extSRAMBases", ...)` rather than
touching the array, so the platform layer can supply it; `_AdjustParam` setting
`Args->extSRAMBases[0]` still feeds it in both eras.

So `gc_hal_kernel_platform_1808.c` would port forward essentially unchanged.
Nothing in the five ops it implements has moved.

### The feature database keeps drifting, and never gains this chip

    release       members   rows in gChipInfo[]
    6.4.6             732           5 - four upstream, plus the one we splice
    6.4.7             744           4
    6.4.13            832           4
    6.4.15 aw         846           4
    6.4.19            904           6
    6.4.21            927           6

Every release adds members, so a row still cannot be moved between them - which
is why `featuredb-emit.py` takes a decoding layout separately from the target.
The drift is worse than the 733-to-745 step already handled: 6.4.6 to 6.4.21 is
195 new members.

And no public release, in any of the six, contains `productID 0x45080001`. The
single occurrence in the 6.4.6 tree is the row this repo splices in - it is
untracked, and labelled `rk1808_0x8000_0x7100 from galcore.ko`. Upgrading the
DDK would not remove the need to extract the row from rockchip's blob.

### Allwinner's driver is stock, and that is the useful part

`Avaota-linux/bsp/drivers/npu/aw_nna_galcore` is a 6.4.15 that sits exactly
where its version number says, between ST's 6.4.13 and 6.4.19 - closer to 6.4.19
in the MMU, 173 changed lines, than to 6.4.13, 308.

Their own content, across the whole tree, is two identifiers: `aw_driver`, 80
references, all in their platform file, and `sunxi_get_module_param_from_sid`,
twice. Per file, against the nearest ST releases:

    file                            vs 6.4.13   vs 6.4.19
    gc_hal_kernel_mmu.c                   308         173
    gc_hal_kernel_hardware.c              490         685
    gc_hal_kernel_command.c                46         257
    gc_hal_kernel.c                       626         362
    gc_hal_kernel_video_memory.c          149         333

That is release drift, not vendor patching. Which is the finding that matters: a
silicon vendor integrating this NPU changes the platform file and nothing else.
It is the same conclusion the reconstruction here rests on, arrived at from
someone else's shipping BSP.

Their platform file is 572 lines against our 274, and declares the same five
ops - `adjustParam`, `getPower`, `putPower`, `setPower`, `setClock`. The extra
length is all board specific, and all of it things the RK1808 does differently:

- three reset controls, `npu_rst`, `npu_axi_rst`, `npu_ahb_rst`, asserted and
  deasserted in order. RK1808 has none; the power domain does this.
- `regulator_get(dev, "npu")` and an opp table parsed by hand out of the device
  tree - `table`, `opp-hz`, `npu-regulator`, `npu-vf`. On RK1808 the regulator
  hangs off the power domain and the rate comes from `assigned-clock-rates`.
- `platform_get_irq_byname(pdev, "galcore")` as a fallback after
  `platform_get_irq`.

Nothing in it is a piece we are missing. It is corroboration that the shape is
right.

No DDK ships an `rk` platform directory. 6.4.13, 6.4.19 and 6.4.21 have
`default` and `st`; the `rk` directory in the 6.4.6 and 6.4.7 trees is untracked
and created by `build-galcore.sh` from this repo.

### The other Allwinner driver is a different thing entirely

`aw_nna_vip`, beside it in the same directory, is not gc_hal at all. It is
VeriSilicon's VIPLite:

    VERSION_MAJOR 1
    VERSION_MINOR 13
    NBG_VERSION   1.30

A separate, much smaller driver that executes NBG - network binary graph - files
directly, rather than the gc_hal command stream. It is not a newer galcore and
it is not a drop in replacement: the RK1808 userspace here talks the gc_hal
ioctl interface through `librknn_api`, and nothing in that stack knows about
NBG. Worth knowing it exists; not a route from here.

### So is any of this worth taking

No, on the evidence:

- the one function group the vendor has and we do not is devfreq, and it is
  absent by choice.
- crossing the 6.4.13 boundary buys a reorganised MMU, 195 more feature database
  members to fill in, and no new chip row - the row still has to come out of
  rockchip's blob either way.
- the userspace pins the build number. It wants 351518. A 6.4.21 driver claiming
  351518 would be a much larger lie than a 6.4.6 one, against a userspace nobody
  can rebuild.

That last point was the weakest of the three, so it was tested rather than left
as an argument. 6.4.21 builds, binds the hardware and accepts the feature row,
then destroys the first real request and wedges the die. The next section has
the measurement and the reason, which turns out to be the ioctl payload layout
rather than anything listed above.

The value in the newer trees is as reference, not as a base: they confirm the
SRAM and platform interfaces are stable, and Allwinner's tree confirms the
platform file is the whole of a vendor's delta.

## 6.4.21 builds, loads, and then wedges the die

The section above argued a newer DDK was not worth trying. That was an
argument, so it was tried. The answer is no, and the reason is not the one the
argument gave.

### Getting it to build

Two changes, both small:

- `setPower` and `setClock` took a `gctUINT32 DevIndex` at 6.4.13, when the DDK
  gained multi-device support. That is the only signature change in the five ops
  `gc_hal_kernel_platform_1808.c` implements, so the file now switches on
  `gcvVERSION_PATCH` and covers 6.4.6 through 6.4.21 unchanged. The test is on
  the patch level and not on `gcvVERSION_BUILD`, because `build-galcore.sh`
  rewrites the build number.
- `featuredb-emit.py` had to learn about array members. 6.4.21 added
  `gctUINT32 VIP_SRAM_SIZE_ARRAY[9]`, and an unbraced array in a positional
  initialiser does not just warn - it swallows the next nine values, so every
  field after it lands in the wrong member. Upstream rows write `{0x0, }` there
  and keep the real value in the scalar `VIP_SRAM_SIZE` beside it, so zeros are
  correct for a chip that predates it. The layout is now 928 members and 600
  bytes, decoded from 6.4.6's 733 and 456.

With those, the tree builds against Linux 6.1.172 and produces a 528696 byte
module, against 666040 for the 6.4.6 build.

### It gets further than expected

    galcore: unknown parameter 'DDRBitWidth' ignored
    galcore ffbc0000.npu: npu at 0x00000000ffbc0000 size 0x1000 irq 32
    Galcore version 6.4.6.5.351518

The platform glue works: the core binds `ffbc0000.npu` and `/dev/galcore`
appears. There is no *Feature database is not found*, so the spliced 928 member
row was accepted. `rknn_server` starts on the die and stays up at 313MB
resident - which is already past the point where the wrong build number kills
it. `DDRBitWidth` is a parameter 6.4.21 no longer has; harmless.

Then loading a model fails:

    E RKNNAPI: rknn_init, recv(MsgLoadAck) fail, -9(ERROR_PIPE) != 368!
    rknn_init failed: -3

and the host side proxy says why:

    E NPUTransfer: usb read failed: ret = -1: LIBUSB_ERROR_IO

The die stops answering ping while still enumerating as 2207:1808. It does not
come back on a service restart - the USB id says it is past maskrom, so nothing
re-downloads - and needs the rails dropped and raised again.

Putting the 6.4.6 module back and running the same model immediately afterwards
gives the same values it always gave:

    output[0]  30672 bytes,  -0.2093 -0.9768 -4.2559 -4.6048
    output[1]  697788 bytes,  3.1013 -5.1239 -9.7084 -7.8207

    PASS - the model ran on the npu

So the rig is sound and the failure belongs to the driver.

### Why: the ioctl payloads, not the command numbers

The userspace here cannot be rebuilt. `librknn_api` on the host and
`rknn_server` on the die are binaries compiled against 6.4.6's headers, and
those headers fix the layout of every ioctl. `ddk-abi.py` beside this file
checks the three things that have to match.

Two of them do match, which is why it gets as far as it does.

The fixed head of `gcsHAL_INTERFACE` - the part read before any command
dispatch - is identical:

    gceHAL_COMMAND_CODES command;   gceHARDWARE_TYPE hardwareType;
    gctUINT32 coreIndex;            gceSTATUS status;
    gceENGINE engine;               gctBOOL ignoreTLS;
    gctBOOL commitMutex;

And `gceHAL_COMMAND_CODES` is intact where it counts. The enum carries no
explicit values, so position *is* the command number, and an insertion would
renumber everything after it. Nothing moved: all 71 codes the two releases share
are at the same index, and the first divergence is at index 65, between
`gcvHAL_SET_DEBUG_LEVEL_ZONE` and `gcvHAL_QUERY_CPU_FREQUENCY` - debug,
profiling and fence codes that this userspace never sends.

What does not match is the payload. 20 of the 64 per-command structs changed
layout, and the command number says nothing about them. The ones on the path a
model load takes:

    gcsHAL_ATTACH
        6  gctBOOL queryCapSize          | gctBOOL shared
        7  gctPOINTER contextLogical[]   | gctBOOL queryCapSize
        8  gctSIZE_T captureSize         | gctPOINTER contextLogical[]
        9  -                             | gctUINT64 captureSize

    gcsHAL_COMMAND_LOCATION
        3  gctUINT32 address             | gctADDRESS address

    gcsHAL_ALLOCATE_LINEAR_VIDEO_MEMORY
        8  -                             | gctINT32 vidMemIndex

    gcsHAL_EVENT_COMMIT
        2  gctUINT32 priorityID          | gctBOOL shared
        3  gctBOOL topPriority           | gctUINT32 priorityID

    gcsHAL_CHIP_INFO
        0  gctINT32 count                | gctUINT16 count
        1  gceHARDWARE_TYPE types[]      | gctUINT8 types[]
        2  gctUINT32 ids[]               | gctUINT8 ids[]

`gcsHAL_ATTACH` is the first thing a context does, and `shared` was inserted
ahead of two existing fields. `gcsHAL_COMMAND_LOCATION.address` is the GPU
address of the command buffer, and `gctADDRESS` is `typedef gctUINT64` at
6.4.21 where the field was a `gctUINT32` at 6.4.6 - the type does not exist in
6.4.6 at all. So the driver reads the buffer address from the wrong offset and
at the wrong width, and hands the hardware a garbage pointer. A stalled AXI
master is exactly what the symptom looks like: no ioctl returns an error, the
transport dies mid-transfer, and only a power cycle recovers it.

### What this actually says

The build number the userspace checks is a red herring, twice over. Claiming
351518 on a 6.4.6 driver works because the code behind it *is* 6.4.6. Claiming
it on 6.4.21 gets past the same check and into a driver that reads every request
at the wrong offsets - the check is not protecting anything it was meant to
protect, and satisfying it proves nothing about compatibility.

Which sharpens the earlier conclusion. The reason not to move to a newer DDK is
not the reorganised MMU, nor the 195 extra feature database members, nor even
the missing chip row. It is that the ioctl payload layout is part of the
contract with a userspace that is binary only, and it broke at the same 6.4.13
boundary everything else broke at. 6.4.6 is not a starting point to be improved
on; it is the version this userspace speaks.

The counterpart is worth stating too: everything *else* ported cleanly. The
platform file needed one parameter, the feature row needed one brace, and the
driver bound the hardware first time. If the userspace could be rebuilt - which
is what an etnaviv/Teflon route would mean - none of this would be in the way.

## What the issue trackers add

Read 2026-08-30: all 66 issues and 2 PRs of `rockchip-linux/rknpu`, all 8 of
`airockchip/RK3399Pro_npu`, all 6 of `airockchip/rknpu_ddk`, and the RK1808 and
3399Pro subset of `rockchip-linux/rknn-toolkit`'s ~515. `airockchip/rknpu` has
no issues at all: it is a byte identical mirror of `rockchip-linux/rknpu`, same
144 commits, same HEAD `e0cb42b6`, differing only in tags - `v1.7.5` exists
only on the airockchip side.

### The source question, on the record

Asked four times over four years, answered never. `rknpu#42`, openedev
(Jagan Teki), 2022-12-07, still open with **zero replies**:

    Can RV1126 NPU drivers be open to using for the latest kernel versions
    or any galcore modules for v5,10 or v6,1 ?

`rknpu#18` (2021-10, a build for 4.19), `RK3399Pro_npu#8` (2024-10, "Linux更新
太快了，能不能提供源码呀，或者ko格式的驱动") and `RK3399Pro_npu#9` (2026-06,
"2026年了…能开放一下源码吗？…想适配个主线Linux都不行") are all open and all
unanswered.

Two statements from Rockchip do exist. `rknpu_ddk#1`, from the `airockchip` org
account, closing the issue:

    There are no plans to support RK3399pro.

And `rknn-toolkit#2`, where `Jerzha` answers a request to open source
`npu_transfer_proxy` - not galcore, but the same wall:

    Sorry, the department responsible for NPU did not open source to us :(
    We will strongly suggest them to open source it.

That is the most informative sentence in any of the trackers. The people
answering issues in rockchip's own linux and toolkit repositories did not have
the NPU source either. It reframes the silence: not a company declining to
publish, but a team that was never given the code to publish. Same outcome for
us, and worth stating accurately.

### Nine galcore versions are in the git history

Only the tip is documented anywhere. Every earlier drop is still fetchable from
the repo history, and between them they cover seven vermagics:

    6.3.1.4.176505    4.4.143  (modversions)   description=Vivante Graphics Driver
    6.3.1.9.179562    4.4.159
    6.3.2.183211      4.4.159
    6.3.2.1.185830    4.4.159, 4.4.167         description=Rockchip NPU Driver
    6.3.2.3.2.187389  4.4.167
    6.3.2.7.195560    4.4.167
    6.3.3.2.203718    4.4.167, 4.4.179, 4.4.185
    6.4.0.2.227915    4.4.167, 4.4.185, 4.4.189, 4.4.194
    6.4.3.5.293908    4.4.185, 4.4.189, 4.4.194
    6.4.6.5.351518    4.4.185, 4.4.194

The first one is the interesting one: it was built **with `modversions`**, so it
carries a `__versions` section - the full symbol CRC list of the kernel it was
compiled against. That is a free cross check on any rebuild, and the only such
artifact in the set.

No prebuilt for 4.19, 5.x or 6.x exists in either repo at any point in history.
The one commit that looks like it ("rknnrt: update npu ko and library to
4.19.161") is the RK356x `rknpu.ko`, a different driver, later deleted.

### The kernel commit behind each prebuilt

The v1.6.0 / v1.7.0 / v1.7.1 release commits name the `rockchip-linux/kernel`
commit each variant was compiled against:

    galcore_rk3399pro-npu.ko, -pcie   577aa02a6d309d0697db079c673baf0b815f5d53
    galcore.ko                        d81e5390d0921d7fb019f3a45ab08d5e0e1d2fb0
    galcore_fedora.ko                 cd3732aee3322203a61905f0a92aa3ca397a6071
    galcore_puma.ko, _puma_tb.ko      7759a5c34e4296cd014ef32b181b9f91b9477557
    galcore_rk1806.ko                 2c962252bb2eacc3c43031f737f5899ed30f20a6

Those are the trees whose `struct device` the prebuilt was compiled against -
the thing that puts the `CONFIG_PCI` floor under the trim. If that floor ever
needs proving rather than inferring, this is the tree to build and compare.

Internal tree names track the same history: `/home/zf/dl/vip/driver/vipgal/rk1808`
(2018), `vip8000/git/vipgal_driver` (2019), then `lion/git/vipgal_driver`, then
per version `vipgal_6.4.3.5` and `vipgal_6.4.6.5`. Two commit messages leak the
internal gerrit - `10.10.10.29:29418`, projects `rk/kernel` and
`rk/rknn-toolkit`.

### A vendor boot log at our exact build

`rknn-toolkit#482` (2024-10) posts a full dmesg from `galcore_puma.ko`,
6.4.6.5.351518, on RV1126 - the vendor glue we reconstructed, running:

    Galcore version 6.4.6.5.351518
    Galcore Info: ContiguousBase=0x7f95a000 ContiguousSize=0x400000
    Galcore Info: MMU mapped core 0 SRAM[0] hardware virtual address=0x400000 size=0x40000
    Galcore Info: MMU mapped core 0 SRAM[1] hardware virtual address=0x440000 size=0x40000
    galcore ffbc0000.npu: Init npu devfreq
    galcore ffbc0000.npu: bin=0
    galcore ffbc0000.npu: leakage=1.250
    galcore ffbc0000.npu: temp=51700, pvtm=105239 (105239 + 0)
    galcore ffbc0000.npu: pvtm-volt-sel=1
    galcore ffbc0000.npu: bin-scale=23
    galcore ffbc0000.npu: avs=0
    galcore ffbc0000.npu: failed to read out thermal zone (-22)
    galcore ffbc0000.npu: failed to find power_model node
    galcore ffbc0000.npu: failed to initialize power model

Two things worth having. The vendor maps **two** 256 KiB SRAM windows, at
hardware virtual 0x400000 and 0x440000. And the vendor stack prints the same
`power_model` and thermal-zone failures this harness prints - independent
confirmation that those are not ours.

Its production insmod, from the init scripts still in the repo, computes the
DDR width from `/proc/meminfo` rather than hardcoding it:

    insmod galcore.ko contiguousSize=0x400000 DDRBitWidth=$bitWidth
    read MAX_FREQ < /sys/class/devfreq/ffbc0000.npu/max_freq
    echo $MAX_FREQ > /sys/class/devfreq/ffbc0000.npu/userspace/set_freq

The deleted RK3399Pro variant of that script passed `gpuProfiler=1` and a
hardcoded 792MHz - `gpuProfiler` is not a parameter in 6.4.6.5, so that script
was already stale when it was removed in 2020.

### The on-die build has no dma-buf and no IOMMU

String diffing the two RK3399Pro variants: only `galcore_rk3399pro-npu-pcie.ko`
and the standalone RK1808 `galcore.ko` contain `[galcore]: Enable IOMMU`,
`iommu_get_domain_for_dev`, `iommu_iova_to_phys` and the dmabuf allocator. The
non-pcie build has the `gckIOMMU_*` symbols with no iommu imports at all. The
on-die path is reserved-CMA only, which is what our config should match.

### Runtime knobs the documentation does not mention

    NN_LAYER_DUMP=1          per layer dump, VeriSilicon side
    RKNN_LOG_LEVEL=5         librknn_runtime
    RKNN_SERVER_LOGLEVEL=5   rknn_server
    TRANSFER_LOG_LEVEL=5     npu transfer
    RKNN_SERVER_PLUGINS=/usr/lib/npu/rknn/plugins/
    VIV_VX_DEBUG_LEVEL, VIV_MEMORY_PROFILE, VSI_NN_LOG_LEVEL, VSI_NN_NBG_FILE

`NN_LAYER_DUMP` is the one to remember. In `rknn-toolkit#258` setting it turned
a graph that **failed** on RV1126 into one that ran correctly but extremely
slowly - which is the signature of forcing per layer sync around a scheduling or
SRAM bug, not of a dump flag. If our own driver ever mis-executes a graph, that
is the first thing to toggle.

On the die those go in `/usr/bin/npuserverd` (before its `case $1`) or
`start_rknn.sh`; `restart_rknn.sh` is `killall start_rknn.sh; killall
rknn_server; start_rknn_wLog.sh &`.

### Transport facts from the trackers

- the aarch64 proxy identifies its host by probing, in order,
  `/sys/devices/platform/ff690000.efuse/rockchip-efuse0/nvmem` - the rk3399
  efuse - then `/sys/devices/system/cpu/soc`, `/socid`, then
  `/proc/device-tree/compatible`. With none of them resolvable it falls back to
  the placeholder devid `0123456789ABCDEF`.
- on the gadget the proxy skips interfaces 0 to 2 and accepts **interface 3** as
  the ntb interface, matching by bulk endpoints: *"Rejecting potential ntb
  interface … missing bulk endpoints"*.
- transfer proxy 2.0.0 exits immediately when run from a shell; 2.1.0 stays
  resident. That is how to tell which one a rootfs has without a version flag.
- `RK3399Pro_npu#3`, never answered: after an npu image update and reset, only
  the **first** `npu_transfer_proxy` process to establish contact can drive the
  npu. Kill it and a restarted proxy cannot get the hardware back. Worth knowing
  before restarting the service on the host.
- `RK3399Pro_npu#2`, answered by eRaul: official firmware lives in
  `/usr/share/npu_fw` whichever transport the board uses, and the way to find
  out which directory a system actually reads is to rename one. He also notes
  Rockchip never shipped the ubuntu 18.04 images boards ship with.

### Positive and negative mode

`rknn-toolkit#2` again, same engineer, on running the stack with a non-rockchip
host:

    We don't support RaspPi in 1808 negative mode communication via
    npu_transfer_proxy, npu_transfer_proxy can't running in arm32. But you can
    try in positive mode which is communication via usb-eth. In this mode 1808
    has a full control with CPU and NPU.

So rockchip's own model of this hardware has two arrangements and only one of
them is the transfer proxy. *Negative* mode is the ntb path the host drives.
*Positive* mode is usb-eth with the die running the application itself.

This harness is positive mode. The route sketched under *The open driver route*
in `README.md` - the die does the inference, the host is a network peer, none of
rockchip's transport in the way - is not a workaround for a missing piece. It is
the vendor's second supported mode, named by the vendor. Worth having on record
the next time the proxy looks mandatory.

### RKNPUTools, and the transport is adb

The pinned advice issue, `rknn-toolkit#274` by `zen-xingle`, points RK3399Pro
users not at `RK3399Pro_npu` but at `rockchip-linux/RKNPUTools` - a repository
absent from our provenance list. 574 files, and it holds two things the others
do not:

    NOTICE                        Apache License 2.0, "Copyright (c) 2005-2008,
                                  The Android Open Source Project"
    ntbd/{README.txt,ntbd,ctbd}   the device side ntb daemon, binaries only
    npu_transfer_proxy/           linux-aarch64, linux-arm, linux-x86_64,
                                  macos-x86_64, windows-x86_64 (+ libusb dll),
                                  android-arm64-v8a, android-armeabi-v7a

The AOSP notice, together with `localabstract`, `local:transfer_proxy` and
`execl` in the binary, says what the proxy is: **adb, re-badged**. Its wire
protocol is therefore public, and a replacement is an implementation job rather
than a reverse engineering one. Note also that a 32 bit `linux-arm` proxy build
exists here despite the statement above that arm32 is unsupported - older or
abandoned, but present.

`ntbd/README.txt` is four lines, and it is the vendor's device side sequence:

    Version: 1.0.3
    1.initialize ntb ffs
    2.ntbd &
    3.export TRANSFER_USB_DEVICE_CONFIG_BYPASS=1
    4.rknn_server &

A different split from the one in our image: there `ntbd` owns the functionfs
endpoints and `rknn_server` is told to bypass gadget configuration entirely,
where ours has no `ntbd` and lets `rknn_server` write the UDC. If ffs.ntb and
rndis ever fight over the gadget, that is the arrangement where neither
`rknn_server` nor our init script owns it.

The proxy also reads the host kernel version (`get_kernel_version`, `reported
kernel version is %s`), so it has an opinion about what it is running on.

### Platform identity is misreported on real 3399Pro hardware

`rknn-toolkit#133`, with three other reporters agreeing in the thread:

    rknn model target platform[0] is RK1806, while current platform is RK3399

All of them on genuine RK3399Pro boards. The runtime resolves the platform to
plain `RK3399`, and refuses RK1808 and RK1806 targeted models; the same class of
report on RV1126 says `current platform is RK1109`. The only reply asks whether
the board is a non-Pro RK3399. Never resolved.

Given the probe order recorded above - efuse, then
`/sys/devices/system/cpu/soc`, then `socid`, then `/proc/device-tree/compatible`
- this is a device tree and efuse question, and nothing in the error says so. On
a 6.1 or 6.12 die, a model that refuses to load with this message is a reason to
look at the dtb, not at the model.

### Smaller things

- `RKNN_SERVER_LOG_LEVEL=5` is a second spelling of the log knob alongside
  `RKNN_SERVER_LOGLEVEL`. Both are in circulation - `rknn-toolkit#274` uses the
  first, `rknn-toolkit#258` the second.
- from the same pinned issue: `rknn_server`'s log goes **only to the serial
  port**, not over the network or the adb channel. Which is why `mods.sh`
  redirects it to a file.
- `rknpu#58`: the npu is float16 only. `float32` in a mixed quantisation config
  means "do not quantise this layer", not fp32 execution. Consistent with this
  die's row - `NNCoreCount 10` against `NNCoreCount_FLOAT16 2`.
- `rknpu#59` carries a `librknn_runtime 1.7.3 (2e55827 build: 2022-08-25
  10:45:32 base: 1131)` stamp. Same `base: 1131` as 1.7.5, a year apart.

### What is not there

No statement about **galcore** source, GPL, or building it, in any of the four
trackers - the two rockchip statements above are about support and about the
transfer proxy. `rockchip-linux/rknpu` is largely unattended: 58 of 66 issues
open, some since 2019, and #15 (a galcore NULL deref after a kernel config
change, on 4.19.111) has never had a reply.

The sweep is finished for `rockchip-linux/rknpu`, `airockchip/rknpu`,
`airockchip/RK3399Pro_npu` and `airockchip/rknpu_ddk` - every issue and PR, and
every comment thread that was not a model conversion question. In
`rockchip-linux/rknn-toolkit` the rk1808 and 3399Pro subset was read, leaving
six threads: version mismatch and lockup reports whose signatures are already
recorded here. Comments were read through a browser, since unauthenticated
api.github.com allows 60 requests an hour and github renders comments client
side. Everything quoted was read, not inferred from a comment count.

## Reproducing

`featuredb.py` beside this file does the decode and the diff. It needs the
public header for the field order and a galcore binary for the rows:

    git clone -b buildroot-ddk-6.4-release \
        https://github.com/heitbaum/npu-driver-amlogic-for-test aml646
    python3 featuredb.py aml646/hal/kernel/inc/gc_feature_database.h \
        vendor/galcore.ko --diff 0x8000:0x7120

It prints the struct layout it derived, both rows found in the binary, and the
diff against any entry in the header. The layout being right is self checking:
if the field order were wrong the two entries in the binary would not be exactly
`sizeof(gcsFEATURE_DATABASE)` apart, and the diff against a two-revision
neighbour would be hundreds of members rather than 17.

`galcore-symcmp.py` does the vendor-against-ours function comparison, folding
gcc's stacked clone suffixes away first - without that it reports four functions
as differing that are the same:

    python3 galcore-symcmp.py vendor/galcore.ko gcnano-driver-6.4.6/galcore.ko

`ddk-compare.py` does the lineage measurements. It takes any number of trees and
finds the files by name, so layouts need not match - ST puts them under
`hal/kernel`, allwinner's bsp under `hal`:

    python3 ddk-compare.py 6.4.6=gcnano-driver-6.4.6 6.4.7=gcnano-driver-6.4.7         6.4.13=ddk/6.4.13 6.4.15aw=Avaota-linux/bsp/drivers/npu/aw_nna_galcore         6.4.19=ddk/6.4.19 6.4.21=ddk/6.4.21

It prints each tree's `gcvVERSION_BUILD` first, which is what caught three
identically-named stm32mp trees being distinct releases.

`ddk-abi.py` compares the ioctl contract - the fixed head of `gcsHAL_INTERFACE`,
the position of every `gceHAL_COMMAND_CODES` entry, and each per-command payload
struct:

    python3 ddk-abi.py 6.4.6=gcnano-driver-6.4.6 6.4.21=ddk/6.4.21

To rebuild the driver against another release, point `build-galcore.sh` at it
and splice the chip row in first, decoding with 6.4.6's layout:

    python3 featuredb-emit.py <tree>/hal/kernel/inc/gc_feature_database.h         vendor/galcore.ko 0x8000:0x7100         gcnano-driver-6.4.6/hal/kernel/inc/gc_feature_database.h
    GALSRC=<tree> KERNEL_DIR=<kernel> SOC_PLATFORM=rk-1808 VERSION_CLAIM=351518         bash tools/build-galcore.sh

The version and provenance strings, without any tooling:

    readelf -p .modinfo galcore_rk3399pro-npu.ko
    strings galcore_rk3399pro-npu.ko | grep -E 'vipgal|VERSION|Galcore'
    readelf -sW galcore_rk3399pro-npu.ko | awk '$7=="UND"{print $8}' | sort -u

## Status of each claim

Verified first hand, by reading the artifact:

- everything in *What the blob is* - from `readelf`/`strings` on the modules in
  `rockchip-linux/rknpu`.
- ST 6.4.6.342038 and Amlogic 6.4.6.2.5.3.2/345497 - from `gc_hal_version.h`
  in each extracted tree.
- the 733 member layout, 456 byte size, and its match to the spacing of the two
  rows in the binary.
- every decoded value and the 17 member diff.
- the NXP, khadas, orangepi and ST version table - each read from source by the
  same method.

- the reconstruction: `/dev/galcore` bound to `ffbc0000.npu` on 6.1, the module
  built from ST source with our platform file, `rknn_server` up and the host
  proxy reading `devid = c509a098222fdbaa`. Read off the running die.
- `chipModel 0x8000 / 0x7100 / 0x45080001 / eco 0x0 / customerID 0x82`, printed
  by our own driver at probe.

Direct evidence rather than an exhaustive search:

- the full public RK1808 vendor SDK contains no galcore source, only the seven
  prebuilt `.ko`. Read from three independent gitlab unpacks and from
  toybrick's kernel.

Searched and not found, which is weaker than proven absent:

- any public copy of `vipgal_6.4.6.5` or a `platform/rk/` directory, now
  including gitee, csdn, cnblogs, software heritage and the rockchip and
  firefly forums.
- any public statement by rockchip on galcore source.

Search coverage caveats, recorded so the above is not overread:

- gitee code search run by hand past its captcha - three queries, all zero; its
  unauthenticated search api answers `[]` to everything and proves nothing.
  baidu unreachable; sourcegraph returned
  zero on a control query with a backend down; searchcode retired; github's
  code index provably incomplete for this filename.

- an inference on the self built driver, output compared value for value
  against the vendor stack. Both run mobilenet ssd; the numbers match.
- the cause of the earlier failure, from a core dump read in gdb rather than
  inferred: `vsi_nn_CreateContext` returning NULL because the driver reported
  build 342038 where the userspace requires 351518.

- the 342038 against 351518 function comparison, and the whole of the lineage
  comparison: `nm` on both modules, and line, token and shingle measurements
  over six extracted trees. The three stm32mp trees were checked distinct by
  `gcvVERSION_BUILD` before use, because they came from one directory.
- that no public feature database carries `0x45080001`, and that the one hit in
  the 6.4.6 tree is this repo's own spliced row - it is untracked and labelled
  as such.
- that no DDK ships an `rk` platform directory, the one present locally being
  created by `build-galcore.sh`.
- that a 6.4.21 driver builds, binds `ffbc0000.npu`, accepts the spliced feature
  row and keeps `rknn_server` alive, then fails model load with `ERROR_PIPE` and
  wedges the die. Run on the hardware, with the 6.4.6 module put back afterwards
  and the same model giving its usual values, so the failure is the driver and
  not the rig.
- the ioctl comparison behind that: head identical, all 71 shared command codes
  at identical indices, 20 of 64 payload structs changed - including
  `gcsHAL_ATTACH`, `gcsHAL_COMMAND_LOCATION` and
  `gcsHAL_ALLOCATE_LINEAR_VIDEO_MEMORY`.

Not checked at all:

- whether devfreq, the one real difference between 342038 and 351518, changes
  anything measurable. The clock is fixed at 800MHz here either way, so it
  should not, but that is reasoning rather than a measurement.
- `aw_nna_vip` beyond its version numbers - not built, not run.
- whether the 20 changed payload structs could be papered over by building
  6.4.21 with 6.4.6's `gc_hal_driver_shared.h`. Not attempted: the driver reads
  those structs everywhere, not only at the ioctl boundary.
