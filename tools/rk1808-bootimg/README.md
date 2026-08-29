# rk1808 boot.img harness

The RK1808 die on an RK3399Pro is a separate SoC with its own Linux. It has no
storage: the RK3399 host holds its `boot.img` and downloads it into the die's
RAM over USB on every power cycle. A bad image cannot brick anything - it just
fails to boot, and the next power cycle returns the die to maskrom.

That makes the image cheap to iterate on, and this is the harness for doing so.
Built and tested on a Radxa ROCK Pi N10 (RK3399Pro, vmarc SoM, dalang carrier).

## Why

The stock image has no way in. The die exposes one USB function, a FunctionFS
gadget (`ffs.ntb`) that the NPU transfer proxy on the host claims, and nothing
else - no console over USB, no network, no shell. Debugging what the die is
doing means either a soldered UART on the NPU_DEBUG pads or nothing at all.

This adds a second USB function beside the NPU one, so the host gets a network
interface to the die and can open a shell on it, while the NPU keeps working.

## Quick start

    tools/run.sh "bash tools/unpack.sh"        # boot.img -> unpacked/ + rootfs/
    tools/run.sh "bash tools/build-kernel.sh"  # kernel/  -> Image
    tools/run.sh "bash tools/dtb.sh"           # -> build/rk-kernel.dtb
    tools/run.sh "bash tools/mods.sh"          # edit the rootfs
    tools/run.sh "DTB=build/rk-kernel.dtb bash tools/build.sh"

Everything runs in a container, so the host needs nothing but docker; `run.sh`
installs the tools it needs on first use.

To build against the newer vendor rootfs instead, see *The 2022 vendor image*:

    tools/run.sh "ROOTFS=rootfs-2022 DTB=build/rk-kernel.dtb bash tools/build.sh"

For a 6.1 kernel on the die instead of 4.4, see *6.1 first, and it boots*:

    tools/run.sh "bash tools/build-kernel-6.1.sh"

Copy `out/boot.img` to `/storage/.config/npu/boot.img` on the RK3399 host and
restart `rk3399pro-npu.service`.

**The die must be power cycled, not reset.** The host service drops its rails on
`stop`, and that is what returns it to maskrom. Skipping the stop leaves it
running the old image and the flash silently does nothing - the tell is the
console timestamps not restarting from zero.

## Layout

    boot.img            the vendor image, as pulled off the host
    MiniLoaderAll.bin   the other three firmware parts, also off the host;
    trust.img             not used by this harness, kept so the set is whole
    uboot.img
    tools/              this directory
    unpacked/           bootimg.py output; kept pristine for the round trip check
    unpacked/resource/  resource.py output: rk-kernel.dtb and the boot logos
    rootfs/             the 2019 ramdisk, extracted - what mods.sh edits
    rootfs-2022/        the 2022 vendor rootfs, same treatment
    kernel/             a kernel tree (rockchip-linux/kernel, develop-4.4)
    ../npu-research/kernel-6.1   the develop-6.1 tree, for build-kernel-6.1.sh
    vendor/galcore.ko   galcore built for the kernel we build
    vendor-new/         the 2022 vendor firmware, unpacked
    build/, out/        intermediates and out/boot.img

`unpack.sh` repacks what it just unpacked and compares it to the input, so a
mismatch in the header modelling shows up before anything is flashed. It is
byte identical on the vendor image.

The boot image's second area is not a raw dtb but a rockchip resource image
(`RSCE`) holding `rk-kernel.dtb` and two boot logos. `resource.py` unpacks and
repacks it, also byte identically.

## Getting in

The host end is addressed by `rk3399pro-npu` when the interface appears, so
after the service has started:

    ping 10.42.0.1
    nc 10.42.0.1 23

The addresses are fixed - 10.42.0.1 on the die, 10.42.0.100 on the host - and
10.42.0.0/24 stays clear of the lan the host sits on. There is no
authentication on that port; it is a private USB link to a debug die.

## The host side

Two files, in the LibreELEC tree rather than here:

    projects/Rockchip/devices/RK3399/filesystem/usr/bin/rk3399pro-npu
    projects/Rockchip/devices/RK3399/filesystem/usr/lib/systemd/system/rk3399pro-npu.service

`rk3399pro-npu` binds the `onboard-usb-dev` platform device to power the die,
downloads `boot.img` when it reaches maskrom, starts the transfer proxy, and
addresses the network interface if the image exposes one. `stop` unbinds, which
drops the rails.

Whether the transfer proxy is a daemon depends on which one is installed -
1.9.7 reads the efuse id and exits, 2.1.0 stays up as the bridge - so the
service backgrounds it either way.

Anything packaged as a standalone repo would need these two carried along, or
reimplemented for whatever host OS it runs on.

## What mods.sh changes

- `galcore.ko` replaced with one built for the kernel we build. The shipped
  module will not load against a different kernel version.
- `rndis.usb0` added to the gadget beside `ffs.ntb`, linked before the UDC is
  written.
- `start_netshell.sh` addresses the interface and starts `inetd`, which serves
  `/bin/sh` on port 23. busybox has `inetd` but no `telnetd`, so this needs no
  binary that is not already in the image.
- the init script is made to call it.

Both rootfs layouts are handled. The 2019 image builds its gadget in
`start_usb.sh` called from `S99NPU_init`; the 2022 image uses `S50usbdevice`,
which reads `.usb_config` and assembles the gadget from flags.

### Why rndis

`rk1808_linux_defconfig` enables `CONFIG_USB_CONFIGFS_RNDIS` and nothing else,
so it is the function rockchip actually test on this stack. ncm binds but
oopses:

    Unable to handle kernel NULL pointer dereference at virtual address 00000000
    PC is at composite_setup+0x864/0xfdc
    Comm: irq/184-dwc3

both alongside `ffs.ntb` and, with the oops avoided by dropping ffs, it still
never completes enumeration - the host retries forever and the die logs
`android_work: did not send uevent` in a loop.

## The kernel we build

    vendor 2019   3,862,536      4.4.185 #1  Dec 2019, gcc 6.3
    vendor 2022   4,974,600      4.4.185 #27 Aug 2022, gcc 6.3
    defconfig    10,977,288      4.4.194, gcc 11.5, untrimmed
    ours          5,453,832      4.4.194, gcc 11.5, 51 symbols trimmed

Neither vendor kernel carries `CONFIG_IKCONFIG`, so their `.config` cannot be
recovered from either image. `build-kernel.sh` enables `CONFIG_IKCONFIG_PROC`
so ours does not have the same problem - `/proc/config.gz` on the die answers
any future question about what is in it.

`rk1808_linux_defconfig` is not what rockchip shipped. It has to cover every
rk1808 product they make, and the 2019 image was trimmed hard enough to have no
network stack at all - `socket()` returns ENOSYS and their own init script
fails to start networking on every boot. That is why a kernel rebuild was the
only way to get a link to the die, not one option among several. The 2022
kernel does have NET, but only `ffs` gadget functions, so it still cannot carry
rndis.

### A megabyte that is not config

`arch/arm64/Makefile` passes `-fno-asynchronous-unwind-tables`, which was enough
for the gcc 6.3 this tree was written for. gcc 11 also needs
`-fno-unwind-tables`, and 4.4's `DISCARDS` does not drop `.eh_frame` either.
Without the flag the image carries an allocated `.eh_frame` of 1,075,328 bytes
that nothing ever reads; with it, `.text` is unchanged and the image loses
exactly 1 MiB.

### The trim

51 symbols: bluetooth, IR, sound, the media stack, drm, fb, vt, scsi, mmc,
wifi, spi, iio, rtc, leds, pps, ptp, pwm, the i2c chardev, the unused on-die
gmac, the host-side usb ethernet drivers, the disk filesystems, and the drivers
for IP the dtb leaves disabled - rga2, the vcodec service, the mipi dphy and
the pcie port services.

Kept because galcore imports it or rndis needs it: `NET`, `NETDEVICES`, `INET`,
`UNIX`, USB gadget, `IOMMU`, `DEVFREQ` + `DEVFREQ_THERMAL`, `REGULATOR`,
`DMA_SHARED_BUFFER`, `THERMAL`, `I2C`, `CLK`. `build-kernel.sh` asserts both
directions and says so if a dependency forces something back on.

Against the 2022 vendor kernel, which is the fair comparison:

                  vendor   ours
    /sys/class      21      23     only in ours: iommu, pci_bus
    /proc           46      47     only in ours: config.gz
    /sys/bus        12      13     only in ours: pci

Nothing is missing in either direction. `config.gz` is deliberate, `iommu` the
npu needs, and `pci` is not optional - see below.

NET is cut to `NET`, `INET`, `NETDEVICES` and `UNIX` - no ipv6, bridging, xfrm,
pf_key, netfilter or AF_PACKET. The evidence that none of that is needed is the
2019 vendor kernel: built `CONFIG_NET=n` outright, and every piece of the die's
own software still ran. `UNIX` is kept only because without it udev loses its
control socket and complains on every boot.

`CRYPTO` cannot go: `net/Kconfig` has `INET` select it, so `/proc/crypto` stays
for as long as we want tcp.

### Why PCI cannot be trimmed

`CONFIG_PCI_MSI` selects `GENERIC_MSI_IRQ`, which guards `msi_list` inside
`struct device`. Turn PCI off and the struct shrinks, every field after it
shifts, and the prebuilt galcore - compiled against a kernel that had it -
reads `dev->of_node` from the wrong offset:

    Unable to handle kernel paging request at virtual address 00080040
    PC is at __of_find_property+0x18/0x60
    ... gpu_init+0x70/0x1000 [galcore]

Nothing else in this tree can select it: the only other path is `ARM_SMMU_V3`,
which itself depends on PCI.

So a binary-only galcore puts a hard floor under the trim, and the floor is
struct layout rather than which symbols are exported. Checking that every symbol
galcore imports still resolves - all 181 of them did - says nothing about this;
only booting it does.

## The device tree

`dtb.sh` takes the board's own dtb and adds a `power-model` node to
`/cpus/cpu@0`, which the shipped one lacks - `rockchip_ipa.c` logs "failed to
find power_model node" without it, and the cpu then fails to read its leakage
value. With it, `cpu cpu0: leakage=21`.

It patches the blob with `fdtput`. Decompiling to dts and recompiling does not
work here: recompiling even an *unmodified* decompile gives 42296 bytes against
the original 42224, and that image boots with every clock reference broken
(`clk: couldn't get clock 0 for /phy@ff380000`), because dtc cannot tell a
phandle from an integer in a decompiled tree. `fdtput` edits in place and leaves
the rest byte for byte - `dtb.sh` asserts the structural diff is exactly the
added lines and nothing removed.

### Why the tree's dtb is not used wholesale

Both vendor images identify as `rockchip,rk3399pro-npu-evb-v10`, "Rockchip
RK3399pro-npu EVB V10 Board" - Radxa ship Rockchip's EVB firmware unmodified.
The tree's dts, and the 2022 image's dtb, add `vdd_npu_1`: a second npu core
supply, a silergy syr827 at i2c 0x40, added in `1eb315258` (2020-05-20).

Sheet 12 of `som-sch-v1.3.pdf` says this board does not have it. The npu power
tree is seven regulators and exactly one is on the die's i2c:

    U2204  LP3985ABI5-08   NPU_VDD_0V8_S3     NPU_PWREN_1    enable only
    U2203  SY8088AAC       NPU_VDD_LOG_S0     NPU_PWREN_2    enable only
    U2207  RT9193-18GB     NPU_VCC_1V8_S3     NPU_PWREN_3    enable only
    U2205  SY8088AAC       NPU_VCC_DDR_S3     NPU_PWREN_H3   enable only
    U2202  SY8088AAC       NPU_VDD_CPU_S0     NPU_PWREN_4    enable only
    U2208  RT9193-33GB     NPU_VCCIO_3V3_S3   NPU_PWREN_5    enable only
    U2206  CS4525          NPU_VDD_S0         NPU_PWREN_6    NPU_I2C1_SDA/SCL

U2206 is the `tcs452x@1c` already in the dtb, annotated "Feedback from RK1808".
There is a syr837 on the som - U2200 - but it feeds VDD_CPU_B on the rk3399
side, on the rk3399's own pmic i2c, nothing to do with the npu.

Booting the 2022 image confirms it. The probe fails and takes a gpio with it:

    fan53555-regulator 1-001c: FAN53555 Option[12] Rev[15] Detected!
    fan53555-regulator 1-0040: failed to get vesl gpio (-16)
    fan53555-regulator 1-0040: Failed to get chip ID!

It is not fatal - the npu comes up anyway - but there is no reason to carry it.

### Why cpu pvtm binning cannot work here

The cpu opp table in the shipped dtb has no `rockchip,pvtm-*` properties while
`rk1808.dtsi` has the full set, so it looks like a device tree gap. It is not.
Taking a pvtm reading means setting the rail to `rockchip,pvtm-volt` first, and
the die's `cpu-supply` is `vdd-cpu`, a `regulator-fixed` at 850000-850000 uV -
U2202 above, an SY8088AAC with an enable pin and a fixed feedback divider.
`vdd-log` behind the dmc is fixed the same way. Adding the properties only moves
the failure one step later, to `Failed to set pvtm_volt`.

The npu rail is the one adjustable supply on the die's i2c, and its pvtm works:

    galcore ffbc0000.npu: temp=48125, pvtm=83861 (84459 + -598)

## Warnings that are not ours

The boot prints a handful of pvtm, thermal and dmc failures:

    rockchip-pvtm fe000000.syscon:npu-pvtm: failed to get rst 0 npu
    rockchip-dmc dmc: could not find power_model node
    galcore ffbc0000.npu: failed to initialize power model

These are not from the trim - an untrimmed defconfig build prints exactly the
same counts. They come from running a 2024 kernel tree against a dtb that
shipped in 2019. The `failed to get rst` ones are `dev_info`, not errors, and no
rk1808 dts has ever given the pvtm nodes `resets`, the current tree included.

## The 2022 vendor image

`airockchip/RK3399Pro_npu` carries a much newer npu firmware under
`drivers/npu_firmware/npu_fw/`, and its rootfs is worth having:

                  2019 (shipped)        2022 (airockchip)
    kernel        4.4.185 #1  Dec 2019  4.4.185 #27 Aug 2022
    rknn_server   0.9.9   Aug 2019      1.7.5   Jul 2023
    NPU Transfer  1.9.7                 2.1.0
    galcore       6.4.6.5.351518        6.4.6.5.351518

The base OS is the same vintage either way - busybox 1.27.2, glibc 2.29,
buildroot 2018.02-rc3 - so what is newer is the npu stack, not the distro. Note
the galcore *driver* version is identical in both; only the kernel it is built
against differs, which is why our own build drops straight in.

Booted unmodified it comes up as **2207:0019**, not 1808. `.usb_config` asks for
`usb_adb_en` + `usb_ntb_en`, giving `CONFIG_STRING=adb_ntb`, and the PID table
has no ntb entry at all - ums, mtp, adb and acm combinations only - so every ntb
config falls through to the `*)` default. `mods.sh` adds an explicit
`ntb | ntb_rndis | rndis_ntb` case at 0x1808, which is what the host service
looks for, and drops adb.

The host side needs the matching proxy from
`drivers/npu_transfer_proxy/linux-aarch64` in the same repo.

## Why the kernel is stuck at 4.4

`rockchip-linux/kernel` maintains rk1808 on develop-4.19, 5.10 and 6.1 - the 6.1
dtsi has commits into December 2023 - but none of that helps the current stack:

- no `rk3399pro-npu-*` board dts on any branch after develop-4.4. What is
  maintained is the standalone rk1808: evb, x4, fpga, compute stick. That part
  we could write.
- `drivers/rknpu` on 6.1 matches rk3568, rk3588, rv1106, rk3562, rk3576 and
  rv1126b, not `rockchip,npu`, which is what the rk1808 npu node still uses.
  `drivers/gpu` there has only `arm` - no vivante, no galcore.
- no galcore published for aarch64 past 4.4.194. The only 4.19 build in
  `rockchip-linux/rknpu` is `galcore_puma.ko`, ARMv7.

And rockchip never published galcore source: there is no vivante driver
anywhere in their 4.4 tree, and no `gc_feature_database.h`. It is a blob, and
the blob is what pins the kernel version - and, through `struct device`, the
config.

That pin has since been removed. `build-galcore.sh` builds galcore from ST's
public 6.4.6 source with `platform/rk/gc_hal_kernel_platform_1808.c` written
here, and the npu runs on it: mobilenet ssd on a 6.1 kernel, output bit
identical to the vendor driver's, with no rockchip binary involved.
`rknn-probe.c` is the test and `GALCORE-SOURCE.md` has the detail.

So a port to 6.1 would boot and do usb gadget with no npu, for as long as
galcore is the only driver.

## The open driver route: etnaviv and Teflon

There is another driver for this hardware. Tomeu Vizoso's work puts VeriSilicon
Vivante NPU support into mesa as a TensorFlow Lite delegate called Teflon,
driving the NPU through the mainline etnaviv kernel driver. Both are upstream,
Teflon is MIT, and it is actively developed - `blog.tomeuvizoso.net`, "Etnaviv
NPU update 22" is dated August 2026.

Not to be confused with his other driver, `rocket`, mainline since July 2025:
that one targets rockchip's own RKNN IP in the rk3588, not the vivante core the
rk1808 has.

### How close is our hardware

The hwdb in `src/etnaviv/hwdb/` is per vendor - amlogic, nxp, st, eys3d,
d-robotics - keyed on ChipID, ChipRevision, ProductID and EcoID. 45 entries,
none of them rockchip. But ChipID `0x8000` is VIP8000, which is our class of
core, and it is already covered across four vendors and seven revisions:

    amlogic      0x8000  rev 0x7004, 0x7120, 0x7131
    nxp          0x8000  rev 0x8002
    st           0x8000  rev 0x6205, 0x6207
    d-robotics   0x8000  rev 0x6214

The NN generation is not a model whitelist either - `etnaviv_screen.c` derives
it from feature bits:

    if (etna_core_has_feature(info, ETNA_FEATURE_NN_XYDP0))     version = 8;
    else if (etna_core_has_feature(info, ETNA_FEATURE_VIP_V7))  version = 7;
    else                                                        version = 6;

### Which core we actually have

galcore embeds the chip database it was built with, as a struct array keyed on
the same four fields mesa uses. Scanning the binary finds exactly two entries,
identical in every rockchip build - `galcore.ko`, `galcore_rk1806.ko`,
`galcore_rk3399pro-npu.ko` and the pcie variant all carry both:

    ChipID 0x8000  rev 0x7100  product 0x45080001  eco 0x0
    ChipID 0x8000  rev 0x8003  product 0x5080009   eco 0x4000000

Which of the two is this die comes from the userspace. `librknn_runtime.so` in
the 2019 image - the one that shipped with the rk1808 - knows exactly one
vivante product, `VIPNANOQ_PID0X82`. The 2022 image adds a second,
`VIP8000NANOSI_PID0XB5`. `libOpenVX.so` prints a `VIP7Version`. So:

    0x8000 rev 0x7100 product 0x45080001   VIPNanoQ       <- this die, VIP v7
    0x8000 rev 0x8003 product 0x5080009    VIP8000NanoSI  <- the newer part

That is the same core as the Amlogic A311D, which is where the etnaviv NPU work
started and is still its best supported target. Compare:

    ours       0x8000  rev 0x7100  product 0x45080001  eco 0x0
    amlogic    0x8000  rev 0x7120  product 0x45080009  eco 0x0

Two revisions apart in the same product line. The second galcore entry is
likewise a near neighbour of nxp's i.MX 8M Plus, `0x8000 rev 0x8002 product
0x5080009`, which is also supported.

Confirmed from the hardware. galcore exports it, so nothing has to be probed
or reverse engineered to get it:

    # cat /sys/devices/platform/ffbc0000.npu/info
    gpu      : 0
    model    : 8000
    revision : 7100
    product  : 45080001
    eco      :    0

which is the first database entry exactly. `version` next to it reads
`6.4.6.5.351518`, the galcore driver version.

Do **not** try to read this with `devmem` on the identity registers at
`0xFFBC0020`. galcore runtime-suspends the block, so the read stalls the bus
and wedges the die; only a power cycle recovers it. The sysfs route above is
safe and needs no new kernel.

### What it would actually take

Not an hwdb entry. Update 18 of that series covers porting from the A311D to
the S905D3 - same vendor, adjacent chip - and the work was reverse engineering
the **weights tensor encoding**, a run-length and Huffman scheme whose
in-memory format differs between chips, from memory dumps. Command stream
programming carried over; the weights format did not. The same had to be done
again for the i.MX 8M Plus.

So the open question is not whether the core is supportable - it is the same
core generation, v7, as the one the driver was written against - but whether
this revision encodes weights the same way the A311D does. If it does, an hwdb
entry and a dts node may be most of it. If it does not, it is a reverse
engineering project of the same shape as update 18.

### Why it would be worth it

It removes the blob, and with it both constraints above. Any kernel version
becomes possible, and the `struct device` floor that forces `CONFIG_PCI` goes
away with the binary module that imposed it.

### What it would not do

It would not remove the need for a transport, and that is the part worth being
clear about before starting.

The only connection between the rk3399 host and the die is USB. The host has
two pci devices and both are on the nvme path; the `/sys/devices/platform/rknn`
node on the host has no driver bound and no device tree node behind it. So the
whole of rockchip's stack crosses one usb link:

    host app
      -> librknn_api.so                        host
      -> npu_transfer_proxy                    host, libusb, /dev/bus/usb
      -> usb, ffs.ntb, 2207:1808 interface .0
      -> rknn_server                           die
      -> librknn_runtime / libOpenVX / libVSC  die
      -> /dev/galcore                          die
      -> npu

Teflon cannot span that. `etna_device_new(int fd)` takes a file descriptor for
a local drm node, and there is no socket, tcp, rpc or usb code anywhere in
`frontends/teflon` or `targets/teflon`. It has to run on the machine the npu is
attached to.

So teflon would replace the die side of that chain - galcore, libOpenVX,
libVSC, the rknn runtime - and nothing else. The transport does not disappear;
rockchip's implementation of it does, and ours would have to take its place.

That makes the real scope:

- a 6.1 kernel for the die, with a board dts written from the rk1808 dtsi that
  is still maintained there
- an hwdb entry for `0x8000 rev 0x7100 product 0x45080001` in mesa
- mesa with teflon, and a tflite runtime, built for aarch64 and running on the
  die's two cortex-a35s - which means building a real rootfs rather than
  editing the vendor buildroot image
- a host to die transport of our own. The one piece of luck is that this
  harness already puts a network link over that usb cable, so it can be
  ordinary tcp to a small service on the die rather than a usb protocol.

Worth noting that `galcore_rk3399pro-npu-pcie.ko` exists and the die's dtb has
a disabled `pcie@fc400000`, which implies designs where the rk1808 is pcie
attached and the host could map the npu directly, with no transport at all.
That is inference from the artifacts rather than something tested, and it is
not this board.

## Putting a mainline kernel on the die

Checked against 7.2, released 2026-08-16, and 7.2.2 stable.

Mainline carries `rk3399pro-rock-pi-n10.dts` and `rk3399pro-vmarc-som.dtsi`,
but those are the rk3399 host - this board's other half. For the rk1808 die
mainline has nothing at all:

    clk-rk1808.c                     absent, the list runs rk3036 to rv1126b
    include/dt-bindings/.../rk1808   absent
    pinctrl-rockchip.c               0 rk1808 hits
    rockchip_thermal.c               0 rk1808 hits
    rk1808.dtsi                      absent
    phy-rockchip-inno-usb2.c         rk1808 not among its 13 socs

All of it lives only in rockchip's `develop-6.1`:

    drivers/clk/rockchip/clk-rk1808.c              whole file
    include/dt-bindings/clock/rk1808-cru.h         whole file
    drivers/pinctrl/pinctrl-rockchip.c             63 rk1808 sites
    drivers/nvmem/rockchip-efuse.c                 36
    drivers/soc/rockchip/pm_domains.c              12, moved to drivers/pmdomain/
    drivers/thermal/rockchip_thermal.c              9
    drivers/phy/rockchip/phy-rockchip-inno-usb2.c   3
    arch/arm64/boot/dts/rockchip/rk1808.dtsi

### What would have to be done

To reach a console: forward port `clk-rk1808.c` and its bindings header across
about ten releases of clk framework drift; move the 63 pinctrl sites into
mainline's restructured driver; translate `rk1808.dtsi` from vendor bindings to
mainline ones; and write a board dts, because no `rk3399pro-npu` board file
exists on any branch - model it on `rk1808-evb-v10.dts` and the dtb in
`unpacked/resource/`, which decompiles cleanly.

The console is easier than the vendor arrangement rather than harder: mainline
wants plain 8250 at `0xff550000`, where the vendor uses an out of tree fiq
debugger on `ttyFIQ0` and leaves `serial@ff550000` disabled. That node just
gets enabled.

To get the host link back: rk1808 data for the inno usb2 phy, the combphy for
usb3, and dwc3 - the vendor uses a `rockchip-dwc3` glue that mainline does not
have, so either `dwc3-of-simple` covers it or new glue is needed.

Then pm-domains, efuse - the transfer proxy reads the efuse id - and tsadc.

### What comes for free

The boot chain, which is usually the painful part. `MiniLoaderAll.bin`,
`uboot.img` and `trust.img` are untouched, ddr is initialised before the kernel
runs, psci comes from atf, and this harness already builds the container the
die expects: an android boot image whose second area is an RSCE resource
holding the dtb. Nothing about the boot protocol changes.

### 6.1 first, and it boots

Vendor `develop-6.1` was the cheap half, and it works. `build-kernel-6.1.sh`
puts Linux 6.1.172 on the die with the shell over rndis:

    usb        2207:1808 speed=5000
    ping       0% loss
    shell      Linux 6.1.172 aarch64
    config.gz  6089 lines

Nothing had to be forward ported. The board description was the only piece
missing from that tree - or so it looked; see the 6.12 section below, where
it turns out rockchip ship both board files on 6.1, 6.6 and 6.12 already
adapted, and their versions are the better base. What follows is what was
done first, not what should be done.

It needed no edits: `rk3399pro-npu.dtsi` and
`rk3399pro-npu-evb-v10.dts` copy straight across from the 4.4 tree, every
dt-bindings header they include is present, every label they reference
resolves against the 6.1 `rk1808.dtsi`, and their bootargs are already right
for a ramdisk boot. The dtsi itself barely moved between the two trees, 3013
lines against 3055.

    git clone --depth 1 --branch develop-6.1 \
        https://github.com/rockchip-linux/kernel.git ../npu-research/kernel-6.1
    tools/run.sh "bash tools/build-kernel-6.1.sh"

One thing did have to be brought back: the combphy, without which usb runs at
480Mbps instead of 5000. That has its own section below.

The script also builds a `-dbg` dtb carrying `rdinit=/bin/sh`, for when the
console is wanted without userspace in the way. Note `rdinit` and not `init`:
this is an initramfs and never switches root, so `init=` is ignored and
`/init` runs regardless.

None of this gets the npu. galcore is built against 4.4 and will not load
here, so `/dev/galcore` is absent and rknn_server restarts in a loop. That is
expected, and it is what the etnaviv section above is about.

### 5Gbps on 6.1: bringing the combphy back

6.1 declares `rockchip,rk1808-combphy` in `rk1808.dtsi`, with its refclk, all
five named resets and both grf phandles, and `rk3399pro-npu.dtsi` wires dwc3 to
it:

    phys = <&u2phy_otg>, <&combphy PHY_TYPE_USB3>;
    phy-names = "usb2-phy", "usb3-phy";

but `drivers/phy/rockchip` there has nothing matching that compatible. The
device tree was kept and the driver was dropped. Without a phy dwc3 stops:

    fd000000.dwc3   dwc3: failed to initialize core

The first cut worked around that by pinning the gadget to usb2, which cost the
usb3 link: 480Mbps against the 5000 the 4.4 tree gets, measured off sysfs on
both.

    4.4    4-1  2207:1808  speed 5000  usb 3.00   (SuperSpeed root hub)
    6.1    3-1  2207:1808  speed  480  usb 2.01   (usb2 root hub)

`combphy-6.1.sh` puts the driver back instead. It is
`phy-rockchip-inno-combphy.c`, which exists on `develop-4.4`, `develop-4.19` and
`develop-5.10` and is gone at 6.1.

**Take it from 5.10, not 4.4.** It is the newest branch that has it, it still
binds `rockchip,rk1808-combphy`, and it is only 7 lines from 4.19 and 45 from
4.4 - the driver barely moved across three kernel generations, so the whole gap
is kernel api rather than hardware support. Against 6.1 it compiles with **no
changes at all**: every header it includes is still there, `gcsPLATFORM`-style
churn does not touch it, and the 21 `combphy` symbols land in `System.map`.
Porting the 4.4 copy would have meant the same driver plus six years of api
drift for nothing.

#### The one real 6.1 regression

Two nodes ask for `<&cru SRST_USB3_OTG_A>`: `usbdrd3` as `usb3-otg` and
`combphy` as `otg-rst`. Both ask **exclusively** - `dwc3-of-simple` through
`of_reset_control_array_get(np, false, ...)`, the phy through
`devm_reset_control_get()`. 4.4 and 5.10 allowed the duplicate silently. 6.1
refuses the second caller:

    WARNING: CPU: 1 PID: 231 at drivers/reset/core.c:766
             __reset_control_get_internal+0x88/0x150

Which caller loses depends on probe order, and that is what makes it nasty.
Built in, the combphy wins and the dwc3 wrapper gets nothing, so **no gadget
comes up at all** - and the gadget is the only console this die has, so there is
nothing left to read. Built as a module and loaded by hand the combphy loses
instead, which is why that configuration looks fine and proves nothing.

Giving the reset to dwc3 and taking it off the phy does not work either:

    rockchip-combphy ff380000.phy: wait phy PLL lock timeout
    rockchip-combphy ff380000.phy: failed to set phy type
    phy phy-ff380000.phy.1: phy init failed --> -110
    dwc3 fd000000.dwc3: error -ETIMEDOUT: failed to initialize core

`phy_u3_init` asserts the controller reset, brings the PLL up, and deasserts it
once lane0 is ready. Without it the PLL never locks. So the phy is the one that
needs it, and `dts-6.1.py` takes it off `usbdrd3` instead -
`of_reset_control_array_get` is called with `optional=true` there, so it is
happy with none, and the phy hands the controller back deasserted before dwc3's
core init runs. That is the order 4.4 ends up in anyway.

    &usbdrd3 {
        /delete-property/ resets;
        /delete-property/ reset-names;
    };

With that, on 6.1:

    6.1 + combphy   4-1  2207:1808  speed 5000  usb 3.20

and the die's console shows no phy warnings at all.

#### What it is actually worth

Less than expected, and worth writing down because the guess was wrong. The
32MB rknn model crosses this link on every `rknn_init`, so a ten times faster
link looked like it should dominate. It does not. One clean run per fresh boot,
alternating:

    5000 Mbps   18936ms   PASS
     480 Mbps   19849ms   PASS
    5000 Mbps   18912ms   PASS
     480 Mbps   19813ms   PASS

About 900ms on a 19 second pipeline, near 5%. The time goes on parsing the model
and building the graph on the die, not on moving the bytes. Measure this per
fresh boot: `runprobe2.sh` restarts the transfer proxy each time and back to
back runs interfere, so every second run in a loop fails and the timings are
meaningless.

The port is still the right thing - it is what the hardware is wired for, it
deletes a workaround, and it is where any future host-side dma or zero-copy work
would have to start - but it is not a throughput fix for this workload.

#### Debugging this needs the serial console

A driver that breaks usb takes the only way in with it. `/dev/ttyUSB1` on the
build host is the die's console and is the only reason this was solvable:

    ssh $BUILD 'nohup sh -c "cat /dev/ttyUSB1 > /tmp/con.log" &'
    ssh $N10   'sh /storage/dieboot.sh <image>'
    ssh $BUILD 'pkill -f "cat /dev/ttyUSB1"; grep -iE "combphy|dwc3" /tmp/con.log'

Every conclusion above came off that log. Before using it, three boots were
blamed on the driver when the real fault was the die not reaching maskrom -
`dieboot.sh` on the n10 exists for that: the service powers the die by
rebinding `onboard-usb-dev` and gives up too early, and the die needs about ten
seconds unbound before it will come back. Always confirm `2207:180a` before
concluding anything about an image.

### 6.12: the whole stack, npu included

Rockchip's BSP has `develop-6.6` and `develop-6.12` branches, and both still
carry every rk1808 piece:

    clk-rk1808.c                     1238 lines
    rk1808-cru.h                     present
    rk1808.dtsi                      3055 lines
    rk3399pro-npu.dtsi                826 lines
    rk3399pro-npu-evb-v10.dts         140 lines

**Linux 6.12.69 runs the whole stack** - usb3 at 5Gbps, the shell over rndis,
and the npu:

    runtime on 4-1: speed 5000 usb 3.20
    Linux buildroot 6.12.69+ #1 SMP PREEMPT aarch64
    galcore ffbc0000.npu: npu at 0x00000000ffbc0000 size 0x1000 irq 31
    Galcore version 6.4.6.5.351518
    [drm] Initialized vivante 1.0.0 for ffbc0000.npu on minor 0

    output[0]  30672 bytes,  -0.2093 -0.9768 -4.2559 -4.6048
    output[1]  697788 bytes,  3.1013 -5.1239 -9.7084 -7.8207
    PASS - the model ran on the npu

Bit identical to the 4.4 vendor stack and to the 6.1 build, and the same speed:
18914 and 18918ms against 6.1's 18925 and 18936, one clean run per fresh boot.

`build-kernel-6.1.sh` builds it unchanged - it takes the tree as `K61`, so the
same script covers 6.1 and 6.12 - and the combphy port needed three more
compat fixes, all of which `combphy-6.1.sh` now detects from the tree rather
than from a version number:

    platform_device.h            6.12 no longer reaches it through of_device.h
    of_xlate const args          6.12 made phy_provider's args const
    remove returns void          6.11 changed platform_driver.remove

One pre-existing BSP bug is in the way: `rga2_mmu_info.c` calls
`get_user_pages_remote()` with the old seven argument signature and does not
build. That is rockchip's, not ours, and this board has nothing to do with rga -
the rga2 and vcodec nodes are `status="disabled"` in the dtb the die boots - so
the build turns `CONFIG_ROCKCHIP_RGA2` off rather than carrying a patch.

#### Correction: the board files were there all along

Earlier notes here said no `rk3399pro-npu` board file existed on any branch
after `develop-4.4`, and `build-kernel-6.1.sh` copied the 4.4 ones across. Both
of those were wrong. `rk3399pro-npu.dtsi` and `rk3399pro-npu-evb-v10.dts` are
tracked on 6.1, 6.6 and 6.12, already adapted - 826 and 140 lines against 4.4's
1393 and 200 - and the script only ever copied because the files it checked for
had been overwritten by hand.

Rockchip's own versions are better than the 4.4 ones and make two of our patches
redundant: `vdd_npu_1`, the syr837 this board does not have, is already gone, and
`&combphy` is already enabled. The regulator moved on too, `tcs,tcs452x` to
`tcs,tcs4525` - worth knowing because mainline 7.2 dropped `tcs,tcs452x`
altogether, so a 4.4-derived dts will not probe its npu supply there.

What is *not* fixed upstream is the reset conflict: `usbdrd3` and `combphy` both
claim `SRST_USB3_OTG_A` exclusively on 6.1, 6.6 and 6.12 alike, so the override
in `dts-6.1.py` is still needed on all of them.

#### The upstream board dts has a pinctrl bug, and it is why the npu never came up

On rockchip's own board dts the npu defers for ever:

    platform ffbc0000.npu: deferred probe pending:
                           platform: supplier 1-001c not ready

`1-001c` is the tcs4525 at i2c1 0x1c, which is `vdd_npu`. The bus comes up, the
device node exists, the `tcs,tcs4525` compatible is matched by the in-tree
fan53555 driver, and every supplier the device links to reports `available` with
`waiting_for_supplier` at 0 - so nothing in the deferred-probe machinery explains
it. Forcing the bind by hand is what says why:

    rockchip-pinctrl pinctrl: unable to find group for node vsel-gpio

rockchip's pinctrl wants two levels under `&pinctrl`, a function node containing
group nodes. 4.4 has that:

    &pinctrl {
        vdd-npu-sleep {                        <- function
            vsel_gpio: vsel-gpio {             <- group
                rockchip,pins = <0 RK_PC6 0 &pcfg_pull_down>;

develop-6.1, 6.6 and 6.12 all flattened it by one level, putting the group
directly under `&pinctrl`. The driver then reads `vsel-gpio` as a function with
no groups and refuses it, `pinctrl-0` on the regulator cannot be applied, the
regulator does not probe, the npu never gets its supply, and galcore loads
without ever getting a `/dev/galcore`. `dts-6.1.py` nests it back.

That single bug is why the npu did not come up on rockchip's own board files on
*any* branch after 4.4, on 6.1 as much as 6.12 - and why using the 4.4 board dts
appeared to be the thing that made the npu work. It was not: it was the nesting.

#### The npu on 6.12: one blocker left

galcore is the harder half, and the reason is structural: **on 6.12 no single
DDK gives both halves.**

- 6.4.6 has the ioctl ABI the die's binary userspace speaks. It also predates
  nine kernel changes and will not compile on 6.12.
- 6.4.21 compiles on 6.12 - ST ship it for exactly that - but 20 of its 64
  ioctl payload structs have moved, which is measured in the section above and
  wedges the die.

So the ABI has to come from 6.4.6 and the kernel glue has to be brought forward.
`galcore-modern.py` does that, and every edit is the form ST use in 6.4.21,
including their `LINUX_VERSION_CODE` guard, so nothing is invented and old
kernels keep the old path:

    class_create owner argument         6.4 dropped it
    gpu_remove returns void             6.11
    get_user_pages vmas argument        6.5 dropped it
    vm_flags_set()                      6.3 made vm_flags read only
    MAX_ORDER -> MAX_PAGE_ORDER         6.4 renamed it
    virt_addr_valid takes a pointer     arm64, 6.12
    dma-resv.h include                  6.2
    dma_resv_lock_interruptible()       6.2 moved dma_buf locking
    _QueryProcessPageTable grafted      pte_offset_map_lock() stopped being
                                        exported after 6.5

That compiled but would not link:

    ERROR: modpost: "__pte_offset_map_lock" undefined!

because `import_pfn_map()` in `gc_hal_kernel_allocator_user_memory.c` walks the
page tables too, and it is the one thing here that could not be lifted. 6.4.21
guards that walk behind `#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 12, 0)` and
uses `follow_pfnmap_start()`/`follow_pfnmap_end()` instead, but its version takes
a different argument list:

    6.4.6   import_pfn_map(gckOS Os, struct um_desc *um, ...)
    6.4.21  import_pfn_map(gckOS Os, struct device *dev, struct um_desc *um,
                           unsigned long addr, size_t pfn_count)

so grafting it would drag its callers along. The `follow_pfnmap` path is written
into 6.4.6's own loop instead, following 6.4.21's shape, with two deliberate
differences:

- `follow_pfnmap_start()` must be called with the mmap lock held, and 6.4.6
  drops it immediately after `find_vma()`. So the lock is taken again around the
  loop and released on every exit from it, including the error path. Getting
  that wrong is a deadlock rather than a compile error.
- 6.4.21's retry through `gckOS_ReadMappedPointer()` is left out. It needs a
  variable 6.4.6's function does not have, and it only converts one failure into
  another for an address the caller should not have passed; failing is what
  6.4.6 already does on a bad walk.

That links, loads, binds and runs.

#### Note on the graft

`function_span()` in `galcore-modern.py` finds a function's end as the first
line that is exactly `}` in column zero, and deliberately does not brace match.
These functions contain `#if`/`#else` pairs where *both* branches carry braces,
so counting them never balances - the first attempt produced an unterminated
`#else` and 30 lines of a neighbouring function. Kernel style always puts the
closing brace in column zero.

### Mainline 7.2 runs the whole stack

    runtime on 4-1: speed 5000 usb 3.20
    Linux 7.2.0 aarch64
    ff550000.serial: ttyS2 at MMIO 0xff550000 (irq = 21) is a 16550A
    galcore ffbc0000.npu: npu at 0x00000000ffbc0000 size 0x1000 irq 29
    Galcore version 6.4.6.5.351518
    [drm] Initialized vivante 1.0.0 for ffbc0000.npu on minor 0

    output[0]  30672 bytes,  -0.2093 -0.9768 -4.2559 -4.6048
    output[1]  697788 bytes,  3.1013 -5.1239 -9.7084 -7.8207
    PASS - the model ran on the npu

Bit identical to the 4.4 vendor stack, at 5Gbps, and near enough the same speed:
19087 and 19068ms against 6.12's 18924, one clean run per fresh boot.

`mainline-7.2.sh` does the whole port and is idempotent. It is worth reading the
scripts rather than this list, but the shape is:

| piece | how |
|---|---|
| four dt-bindings headers | copied; the vendor dts chain includes them |
| `rk1808.dtsi`, dram timing, board dtsi and dts | copied |
| `clk-rk1808.c` | copied, then `mainline-7.2-clk.py` for three framework changes |
| rk1808 register map in `clk.h` | inserted; mainline has the same block for every other part |
| pinctrl | `mainline-7.2-pinctrl.py`, 135 lines of data plus an enum and three switches |
| pmdomain, usb2 phy | `mainline-7.2-rows.py` |
| combphy | `combphy-6.1.sh`, the same develop-5.10 driver as the bsp builds |
| board dts | `dts-6.1.py` for the shared bugs, then `mainline-7.2-dts.py` for the console |
| galcore | `build-galcore.sh` with `galcore-modern.py`, six more edits than 6.12 needed |

#### What actually needed thought

**The clk driver.** Three things, each solved by reading how mainline's own
rockchip drivers do it rather than by shimming:

- `rockchip_clk_register_armclk` takes parent *names* in mainline and indexes
  them by the register values already in the reg_data - clk-cpu.c does
  `&parent_names[reg_data->mux_core_main]`. rk1808 has `mux_core_main = 0` and
  `mux_core_alt = 2`, so the array is `{ "apll", "dpll", "gpll" }`. The bsp
  passed `clks[PLL_APLL]` and `clks[PLL_GPLL]` as pointers instead.
- the bsp has a whole branch type, `branch_muxpmugrf`, for a mux that lives in
  the pmu grf. Mainline has one grf mux type plus a hashtable of auxiliary grf
  regmaps keyed by `grf_type`, so `MUXGRF` takes `grf_type_pmu0` and the driver
  registers the pmugrf in the table. clk-rk3528.c is the pattern.
- `rk_dump_cru` is a bsp-only debug hook with no counterpart. Dropped.

**pinctrl transplants almost whole.** Mainline's `rockchip_pin_ctrl` has every
field the vendor rk1808 definition sets, and in all three switches on
`ctrl->type` the bsp groups RK1808 with RV1108/RK3188/RK3288, which mainline
also has - so `case RK1808:` simply joins them. Two things do not carry:
mainline has no `slew_rate_calc_reg` at all, so that callback and its
`RK1808_SR_*` defines are left behind rather than carried as code the compiler
would reject as unused; and `RK1808` has to be added to
`enum rockchip_pinctrl_type`.

**The usb2 phy cfg does not transplant whole.** Six initialisers name members
mainline's `rockchip_usb2phy_port_cfg` and `rockchip_chg_det_reg` do not have -
`bypass_dm_en`, `bypass_sel`, `iddig_output`, `iddig_en`, `vbus_det_en` and
`chg_mode`. All are vendor extensions. dwc3 here is `dr_mode = "peripheral"` so
the otg id is never read, and the die is a peripheral on a fixed host link so
nothing asks for charger detection.

**pmdomain has one thing that cannot be expressed.** The bsp marks the vio
domain `DOMAIN_PX30_PROTECT`, which expands to a `DOMAIN_M` taking an eighth
`keepon` argument mainline's does not have. vio is display and camera, neither
fitted here, so it is declared with plain `DOMAIN_PX30` and loses only the
never-power-off flag.

#### galcore on 7.2: six more than 6.12

On top of the 6.12 set, and the first one is the reason the others were even
visible:

- **kbuild dropped `EXTRA_CFLAGS`.** `scripts/Makefile.lib` has no mention of it
  at 7.2. The ddk puts every `-D` and `-I` through it, so all of them were
  silently discarded and the build failed as `gc_hal_kernel_linux.h: No such
  file or directory` and `'gcdENABLE_DRM' is not defined`. `ccflags-y` is the
  documented replacement and has been for years, so the rename is unconditional.
- `in_irq()` is now `in_hardirq()`.
- `nth_page()` is gone. It was deleted because the page array is contiguous on
  every config that matters, so it was always pointer arithmetic - which is what
  the shim does, in the common header because four files use it.
- `strncpy()` is gone outright; string.h names it only in comments as the thing
  to stop using. Every call site copies a name into a fixed buffer and ignores
  the return, which is what `strscpy` is for, and it guarantees the NUL
  termination strncpy did not.
- `MODULE_IMPORT_NS` needs a string literal now: 6.12 has
  `MODULE_INFO(import_ns, __stringify(ns))`, 7.2 has `MODULE_INFO(import_ns, ns)`.
- `struct drm_driver` lost `.date`.

#### Two faults the first working boot still had

Both showed up in the console log after the stack was already running, which is
the point of reading it rather than stopping at PASS.

**A kernel WARNING every time rknn_server started.**

    WARNING: drivers/gpu/drm/drm_file.c:329 at drm_open_helper, rknn_server
      drm_open_helper / drm_open / drm_stub_open / chrdev_open / openat

That line is `WARN_ON_ONCE(!(filp->f_op->fop_flags & FOP_UNSIGNED_OFFSET))`, and
it returns -EINVAL, so rknn_server's open of `/dev/dri/card0` failed. This was
self inflicted: `FOP_UNSIGNED_OFFSET` is what replaced the old
`.llseek = no_llseek` idiom, and the no_llseek removal above dropped the old form
without adding the new one, leaving `viv_drm_fops` declaring neither. Every drm
fops helper in mainline - `DEFINE_DRM_GEM_FOPS`, drm_accel.h,
drm_gem_dma_helper.h - sets exactly that flag.

**A warning about the pmu grf on every boot.**

    rk1808_clk_init: no rockchip,pmugrf, clk_32k_ioe will not work

The phandle is there and the node is a proper syscon, so the lookup should have
worked. It cannot: `of_clk_init()` runs from `time_init()`, before the initcalls
regmap needs, and neither `syscon_regmap_lookup_by_phandle()` nor
`syscon_node_to_regmap()` can map anything that early. clk-rk3528.c gets away
with the aux grf pattern because it is a platform driver only; clk-rk1808.c has
a CLK_OF_DECLARE as well, and that is the path that runs.

Nothing is lost: the only user of `clk_32k_ioe` is the cru node's own
assigned-clocks, and no consumer on this board takes the clock. So the message
now says what is actually happening instead of implying a fault.

With both fixed the boot log has no kernel WARNING in it at all - the one that
remains is ATF's, about OPTEE not being provided by BL2, and predates the kernel.

#### Three things about getting a console

Worth writing down because each cost a boot and none is obvious.

`earlycon=uart8250,mmio32,0xff550000` is the whole reason this was tractable. It
pokes the uart with no driver, no clock and no device tree, so a kernel that
dies before anything probes still says where. But it holds no clock reference,
so late_initcall's "Disabling unused clocks" gates the uart and the log stops
mid-boot looking exactly like a hang - hence `clk_ignore_unused` until the real
console probes.

arm64 `defconfig` produces a 41MB Image, and u-boot refuses the resulting 57MB
boot image with `Android image load failed`. The bsp `rk1808_linux_defconfig`
gives 14.8MB and works.

And the console uart is not enabled by the vendor board dts at all. What that
dts enables is the *fiq-debugger* node, which borrows uart2's pins through
`pinctrl-0 = <&uart2m0_xfer>` and `rockchip,serial-id = <2>`; mainline has no fiq
debugger, so uart2 stays `status = "disabled"`, there is no `/dev/console`, and
init dies with `Attempted to kill init!`. Beware the near miss when testing for
this: `"&uart2"` is a substring of `"&uart2m0_xfer"`, so a plain string test
says the uart is already enabled on a dts where the compiled dtb says otherwise.

#### The pinctrl nesting bug bites here too, harder

The same flattened-group bug as the bsp trees - see the 6.12 section - and on
mainline it is worse: the failure takes the whole pinctrl probe down rather than
one consumer, so everything that names a pinctrl state waits for ever:

    dwc3-of-simple usb: deferred probe timeout, ignoring dependency
    ff500000.i2c: deferred probe pending: wait for supplier /pinctrl/i2c1/i2c1-xfer
    gpio-keys:    deferred probe pending: wait for supplier /pinctrl/pwr-key

`dts-6.1.py` now nests every flattened group, not just `vsel_gpio`.

#### As a patch series

The mainline work is also on the `rk1808` branch of `heitbaum/linux`, twelve
commits on top of v7.2, split so each is reviewable on its own:

    dt-bindings: clock: add rk1808 cru bindings
    dt-bindings: power: add rk1808 power-domain bindings
    dt-bindings: add the vendor headers rk1808.dtsi includes
    clk: rockchip: add rk1808 register definitions
    clk: rockchip: add rk1808 clock driver
    pinctrl: rockchip: add rk1808 support
    pmdomain: rockchip: add rk1808 support
    phy: rockchip: inno-usb2: add rk1808 support
    phy: rockchip: add the inno combphy driver
    arm64: dts: rockchip: add rk1808 soc dtsi
    arm64: dts: rockchip: add rk3399pro-npu board files
    arm64: configs: add rk1808_linux_defconfig

20 files, 7908 insertions, no deletions. Each commit that departs from the
vendor code says so and why - the dropped usb2 phy members, the vio domain
losing its keepon flag, the missing slew rate hook, the pmugrf that cannot be
mapped from CLK_OF_DECLARE.

The series was checked the only way that means anything: a kernel built from
those twelve commits alone, with nothing from the working tree, boots the die at
5Gbps and runs the model to the same values. Worth knowing when repeating that -
the series tree is clean, so it builds `7.2.0` where a working tree builds
`7.2.0-dirty`, and galcore has to be rebuilt against it or it will not load.

#### Still to do

- efuse and tsadc have no rk1808 rows. Nothing needed so far depends on them:
  the efuse carries the serial the transfer proxy reads - it reports
  `devid = c3d9b8674f4b94f6` from the u-boot supplied `androidboot.serialno`
  instead - and tsadc is thermal throttling.
- ~~the uart2 pinctrl state is deleted rather than used~~ and
  ~~`clk_ignore_unused`~~ - both were needed only while pinctrl had no rk1808
  data. Tried without them once pinctrl was in and the boot is clean, so both
  are gone. The board dts override is now just `&uart2 { status = "okay"; }`.
- the vendor init script still looks for `/sys/class/devfreq/ffbc0000.npu`,
  which needs the devfreq hookup the platform file deliberately leaves out.

### What is left for mainline

6.1 booting means the packaging, the console, the gadget and the board dts are
all proven, so mainline is now a scoped forward port with a known good
reference to diff against rather than an open question. The list in the table
above is unchanged - clock driver, bindings header, 63 pinctrl sites, efuse,
pm-domains, thermal, phy - plus the combphy driver, which is now known to port
from develop-5.10 with no source changes at all, and to need only the reset
ownership fix in the board dts. Mainline would inherit both.

### What it buys

A modern kernel, a mainline usb gadget stack rather than a 4.4 one, no blobs,
and the base etnaviv would need. It does **not** buy a working npu: without
galcore and without etnaviv the accelerator is dark. This is groundwork, not a
result on its own. And nobody maintains rk1808 outside rockchip's vendor
branch, so upstreaming any of it would be new work.

## Provenance

Everything third party, and where it came from:

    boot.img (2019)     pulled off the board, /storage/.config/npu/boot.img
    boot.img (2022)     github.com/airockchip/RK3399Pro_npu
                          drivers/npu_firmware/npu_fw/boot.img
    npu_transfer_proxy  same repo, drivers/npu_transfer_proxy/linux-aarch64
    galcore.ko          github.com/rockchip-linux/rknpu
                          drivers/npu_ko/galcore.ko               vermagic 4.4.194
                          drivers/npu_ko/galcore_rk3399pro-npu.ko vermagic 4.4.185
    kernel source       github.com/rockchip-linux/kernel, develop-4.4
    schematics          som-sch-v1.3.pdf, carrier-sch-v1.1.pdf (Radxa)

The galcore modules and the npu userspace libraries are binary only. Their
licensing has not been reviewed, and would need to be before any of this is
redistributed.

## Not done

- u-boot and the kernel are still the vendor 4.4 tree, not mainline.
- the rootfs is a vendor buildroot image, edited in place rather than built.
- no end to end inference test. "The npu works" here means galcore loads,
  rknn_server runs, and the transfer proxy reads the efuse id.
- `/proc/crypto` would need `CONFIG_CRYPTO=n`, which INET will not allow.
