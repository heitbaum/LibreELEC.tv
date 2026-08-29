# Session transcript: galcore source availability

2026-08-30. Working notes behind `GALCORE-SOURCE.md` - the questions asked, the
commands run, and the raw output they produced, so every claim in that document
can be checked or re-run.

Everything below ran in a throwaway linux container, not on the build host. The
rockchip modules were taken from `rockchip-linux/rknpu` rather than from the
board, so the artifacts are the published ones.

---

## Q1 - "is galcore source code available"

Answered generally first: the kernel module is GPL and published by several SoC
vendors (NXP i.MX in `Freescale/kernel-module-imx-gpu-viv` and `linux-imx`
`drivers/mxc/gpu-viv`, older drops archived at `etnaviv/vivante_kernel_drivers`);
the userspace - libGAL, libVSC, the EGL/GLES/OpenCL implementations - is
binary only everywhere. Open alternative is etnaviv plus mesa.

## Q2 - "looking for rockchip galcore"

First correction: no rockchip SoC uses a Vivante GPU (they are all Mali), so
galcore on rockchip is the NPU driver - RK1808/RK1806, RK3399Pro, RV1109/RV1126.

    $ git clone --depth 1 https://github.com/rockchip-linux/rknpu
    $ ls rknpu/drivers/npu_ko
    galcore.ko
    galcore_fedora.ko
    galcore_puma.ko
    galcore_puma_tb.ko
    galcore_rk1806.ko
    galcore_rk3399pro-npu-pcie.ko
    galcore_rk3399pro-npu.ko

Binaries only. Checked whether the source is anywhere in rockchip's kernel:

    $ git clone --filter=blob:none --no-checkout --depth 1 -b develop-4.4 \
        https://github.com/rockchip-linux/kernel rkkernel
    $ git ls-tree -r --name-only HEAD | grep -iE 'gc_hal|galcore|rknpu'
    (nothing - only arch/arm64/configs/rk3399pro_npu{,_pcie}_defconfig exist)

    $ git fetch --depth 1 --filter=blob:none origin develop-4.19
    $ git ls-tree -r --name-only FETCH_HEAD | grep -iE 'gc_hal|galcore|rknpu'
    drivers/rknpu/Kconfig
    drivers/rknpu/Makefile
    drivers/rknpu/rknpu_drv.c
    ... (the later RKNN IP, not this driver)

    $ # same for develop-5.10: drivers/rknpu present, no gc_hal, no galcore

## Q3 - "galcore rk3399pro"

    $ readelf -p .modinfo galcore_rk3399pro-npu.ko | grep -E \
        '^(license|description|vermagic|alias|depends)='
    license=Dual MIT/GPL
    description=Rockchip NPU Driver
    alias=of:N*T*Crockchip,npu*
    depends=
    vermagic=4.4.185 SMP preempt mod_unload aarch64

    $ file galcore_rk3399pro-npu.ko
    ELF 64-bit LSB relocatable, ARM aarch64, version 1 (SYSV),
    BuildID[sha1]=27cc4773514c22cd14839d3d7beba8ab543624aa, not stripped

    $ strings galcore_rk3399pro-npu.ko | grep -E 'vipgal|VERSION|Galcore'
    $VERSION$6.4.6:351518$
    6.4.6.5.351518
    Galcore version %d.%d.%d.%d
    /work/projects/lion/git/vipgal_6.4.6.5/hal/os/linux/kernel/gc_hal_kernel_os.c
    /work/projects/lion/git/vipgal_6.4.6.5/hal/os/linux/kernel/allocator/default/gc_hal_kernel_allocator_gfp.c
    /work/projects/lion/git/vipgal_6.4.6.5/hal/os/linux/kernel/platform/rk/gc_hal_kernel_platform_1808.c

The BSP-only imports, which are a second pin on top of vermagic:

    $ readelf -sW galcore_rk3399pro-npu.ko | awk '$7=="UND"{print $8}' \
        | grep -iE 'rockchip|opp|monitor|ipa' | sort -u
    dev_pm_opp_get_voltage
    dev_pm_opp_of_remove_table
    devfreq_recommended_opp
    devfreq_unregister_opp_notifier
    devm_devfreq_register_opp_notifier
    rockchip_init_opp_table
    rockchip_ipa_get_static_power
    rockchip_ipa_power_model_init
    rockchip_monitor_dev_high_temp_adjust
    rockchip_monitor_dev_low_temp_adjust
    rockchip_system_monitor_register
    rockchip_system_monitor_unregister

What the pcie variant imports that the plain one does not:

    $ comm -23 <(undef pcie) <(undef npu)
    dma_buf_attach dma_buf_detach dma_buf_export dma_buf_fd dma_buf_get
    dma_buf_map_attachment dma_buf_put dma_buf_unmap_attachment
    iommu_get_domain_for_dev iommu_iova_to_phys mutex_lock_interruptible seq_puts

Module parameters, from `.modinfo` - 30 of them, all implemented in the public
6.4.6 source: `showArgs`, `enableNN`, `sRAMBases`, `sRAMSizes`, `extSRAMBases`,
`registerBases`, `irqs`, `powerManagement`, `recovery`, `stuckDump`, `isrPoll`,
`softReset`, `mmuDynamicMap`, `type`, and the rest.

## Q4 - "in-depth internet search for the source"

Three parallel searches: Amlogic/Khadas trees, ST/NXP/other vendor trees, and a
hunt for any leaked or mirrored rockchip copy. Every version below was read out
of `gc_hal_version.h` in an actual checkout, not from a description.

### Negative results

    grep.app  "gc_hal_kernel_platform_1808"  ->  {"hits":{"total":0}}
    grep.app  "351518"                       ->  unrelated repos only
    grep.app  "ZRL_7BIT"                     ->  0 (mesa is not indexed there)

No `platform/rk/` directory in any public gc_hal tree. The full set of vendor
glue directories that do exist: `default`, `st`, `freescale`, `amlogic`,
`allwinner`, `hyxt`.

A full RV1126 rockchip SDK dump (41,124 files) has no `gc_hal`/`galcore` source;
its `buildroot/package/rockchip/rknpu/rknpu.mk` installs a prebuilt `.ko`.

`rockchip-linux/rknpu` issue #18 (Oct 2021) asks for a 4.19 build - still open,
no reply. No GPL source request found anywhere public.

Not checked: gitee.com, unreachable from the container.

### Positive results

    $ git clone --depth 1 -b gcnano-6.4.6-binaries \
        https://github.com/STMicroelectronics/gcnano-binaries st646
    $ tar xf st646/gcnano-driver-6.4.6.tar.xz
    $ grep -E 'gcvVERSION_(MAJOR|MINOR|PATCH|BUILD|STRING)' \
        gcnano-driver-6.4.6/hal/kernel/inc/gc_hal_version.h
    #define gcvVERSION_MAJOR        6
    #define gcvVERSION_MINOR        4
    #define gcvVERSION_PATCH        6
    #define gcvVERSION_BUILD     342038
    #define gcvVERSION_STRING    "6.4.6.342038"

    $ ls gcnano-driver-6.4.6
    Kbuild  Makefile  config  hal
    $ ls gcnano-driver-6.4.6/hal/os/linux/kernel/platform/
    default  st
    $ wc -l gcnano-driver-6.4.6/hal/os/linux/kernel/platform/st/*.c
    497

    $ git clone --depth 1 -b buildroot-ddk-6.4-release \
        https://github.com/yan-wyb/npu-driver-amlogic-for-test aml646
    $ grep -E 'gcvVERSION_(PATCH|BUILD|STRING)' \
        aml646/hal/kernel/inc/gc_hal_version.h
    #define gcvVERSION_PATCH        6
    #define gcvVERSION_BUILD     345497
    #define gcvVERSION_STRING    "6.4.6.2.5.3.2"
    $ ls aml646/hal/os/linux/kernel/platform/amlogic/
    gc_hal_kernel_platform_amlogic.c   (649 lines)
    gc_hal_kernel_platform_c308x.c     (511)
    gc_hal_kernel_platform_pico.c      (453)
    gc_hal_kernel_platform_vim3.c      (179)

Other trees, same method: khadas/linux `khadas-vims-4.9.y`
`drivers/amlogic/npu` 6.4.8.7.1.1.1/415784 (5.4 and 5.15 branches have none);
`khadas/android_vendor_amlogic_npu` @de38907 6.4.6.2.2.2.1/345497;
orangepi A733 6.4.18.6.904649, A527 6.4.15.3.690884; nxp-auto-linux/galcore
6.4.0.p2.234062; coral imx-gpu-viv-ko 6.4.2.256507; linux-imx lf-5.10.y
6.4.3.p2.336687, lf-5.15.y 6.4.3.p4.398061, lf-6.1.y 6.4.11.p2.711242, lf-6.6.y
6.4.11.p2.745085, lf-6.12.y 6.4.11.p4.1190909; Freescale ko master
6.4.11.p3.1049711. The NXP line has no 6.4.6 at all.

### How much is missing

Each source path named in the blob, checked against the ST 6.4.6 tree:

    YES  hal/os/linux/kernel/gc_hal_kernel_os.c
    YES  hal/os/linux/kernel/allocator/default/gc_hal_kernel_allocator_gfp.c
    NO   hal/os/linux/kernel/platform/rk/gc_hal_kernel_platform_1808.c

## The feature database

Noticed that both public 6.4.6 trees carry `gc_feature_database.h`, which
rockchip's tree does not, and that its struct is what the blob's chip rows are.

    AML fields: 733 members (91 u32, 1 ptr, 641 bitfields)
    ST  fields: 733 members
    identical member order: True
    computed sizeof: 91*4 + 8 + 21*4 = 456 bytes

Located both rows in the binary by identity words:

    entry 1  0x3b850   0x8000 0x7100 0x45080001 0x0
    entry 2  0x3ba18   0x8000 0x8003 0x05080009 0x4000000
    delta    456       == computed sizeof, so the layout is confirmed

Decoded (`featuredb.py`, written for this and left beside these notes):

    row 0  chipID 0x8000  chipVersion 0x7100  productID 0x45080001
           ecoID 0x0  customerID 0x82
        NNCoreCount 10   NN_ACTIVE_CORE_COUNT 10   NNCoreCount_INT8 10
        NNCoreCount_INT16 2   NNCoreCount_FLOAT16 2   NNMadPerCore 64
        TPEngine_CoreCount 6   VIP_SRAM_SIZE 524288   AXI_SRAM_SIZE 2031616
        NNInputBufferDepth 12   NNAccumBufferDepth 64
        VIP_V7 1   NN_XYDP0 0   NN_ZDP3 1   TP_ENGINE 1
        ZRL_7BIT 1   ZRL_8BIT 0   NN_INTERLEVE8 1
        NN generation 7  (mesa etnaviv rule)

    row 1  chipID 0x8000  chipVersion 0x8003  productID 0x5080009
           ecoID 0x4000000  customerID 0xb5
        NNCoreCount 4   TPEngine_CoreCount 2   VIP_SRAM_SIZE 262144
        AXI_SRAM_SIZE 0   NN_XYDP0 1   NNCoreCount_FLOAT16 0
        NN generation 8

`customerID` 0x82 and 0xb5 match `VIPNANOQ_PID0X82` and `VIP8000NANOSI_PID0XB5`
from the die's userspace - the identification in `README.md` confirmed from the
driver instead of inferred from the libraries.

Same two rows, byte identical, in `galcore.ko`, `galcore_rk1806.ko` and
`galcore_rk3399pro-npu.ko`, as `README.md` says.

Diffed row 0 against the A311D row published in the Amlogic header
(`0x8000 rev 0x7120 product 0x45080009`):

    row 0: 17 of 733 members differ

    chipVersion                        0x7100     0x7120
    productID                          0x45080001 0x45080009
    customerID                         0x82       0x88
    NNCoreCount                        10         8
    NN_ACTIVE_CORE_COUNT               10         8
    NNCoreCount_INT8                   10         8
    NNCoreCount_INT16                  2          8
    NNCoreCount_FLOAT16                2          0
    TPEngine_CoreCount                 6          4
    AXI_SRAM_SIZE                      2031616    1048576
    NN_XYDP6                           0          1
    NN_CACHELINE_MODE_PERF_FIX         1          0
    NN_ZXDP3_KERNEL_READ_CONFLICT_FIX  0          1
    NN_ASYNC_COPY_PERF_FIX             0          1
    NN_JD_DIRECT_MODE_FIX              1          0
    NN_INTERLEVE8                      1          0
    ZRL_7BIT                           1          0

Row 1 against the same reference differs in 81 members, as expected for the
newer part.

`ZRL_7BIT` and `NN_INTERLEVE8` are the two that sit in the weights encoding
path, which is the part the etnaviv porting work turned on.

## Follow ups

- `grep -rn "ZRL_7BIT\|ZRL_8BIT\|NN_INTERLEVE8\|NN_XYDP6" src/etnaviv/` against
  a mesa checkout. Could not be run here: `gitlab.freedesktop.org` is blocked
  by the container's egress proxy and no usable github mirror exists.
- gitee.com search for a rockchip source mirror, also blocked here.
- A `platform/rk/gc_hal_kernel_platform_1808.c` written against the public
  6.4.6 tree, if a source build is ever worth doing.

## Repos taken locally

    heitbaum/gcnano-binaries                  fork of STMicroelectronics/,
                                              200 MiB, every DDK 6.2.4 - 6.4.21
    heitbaum/npu-driver-amlogic-for-test      fork of yan-wyb/, 31 MiB, 6.4.6.2
