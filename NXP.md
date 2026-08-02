# NXP i.MX8MQ — Coral Dev Board (phanbell)

Working notes for the NXP project on `dev`, written while bringing the board up
on linux 7.2-rc5. Everything here was observed on hardware unless it says
otherwise.

- Project: `projects/NXP`, `DEVICE=iMX8`, `LINUX="default"` (so 7.2-rc5)
- Board: Google Coral Dev Board, `imx8mq-phanbell`, upstream dts exists but
  enables none of this
- Patches: `projects/NXP/devices/iMX8/patches/linux/`

## Board topology

| | device | REF_CLK source |
|---|---|---|
| pcie0 `33800000` | Atheros QCA6174 wifi `168c:003e`, driven by `ath10k_pci` | internal PLL, SoC drives 100 MHz out on CLK2_P/N |
| pcie1 `33c00000` | Edge TPU `1ac1:089a`, driven by `apex` (staging, not in our build) | off-chip oscillator on the pad |

pcie0 negotiates Gen1 (`fsl,max-link-speed = <1>`), pcie1 Gen2. Both match what
the vendor Mendel image does.

Mendel binds `hif_pci` (Qualcomm's out-of-tree qcacld) to the wifi; we use
upstream `ath10k`, which wants entirely different firmware.

## Current state

Works: both PCIe ports, ath10k with firmware, and — separately — HDMI.

All four work together with `clk_ignore_unused` on the kernel command line.
Without it, enabling the display stops pcie0 linking - see open problem 1 for
why, and the narrow fix that should remove the need for the flag.

## Patches

| patch | what | status |
|---|---|---|
| `0001` | Cadence MHDP8501 HDMI/DP driver (NXP out-of-tree, ~6600 lines) | downstream only |
| `0002`–`0004` | evk / pico-pi / phanbell DCSS + HDMI enablement | downstream, needs `0001` |
| `0005` | `PCI: imx6: Avoid dereferencing a NULL clock name` | **submitted 2026-08-02** |
| `0006` | phanbell Coral specifics (pcie0/pcie1, i2c, gpio) | needs `0008` resolved |
| `0007` | `PCI: imx6: Select the PCIe REF_CLK source on i.MX8MQ` | **submitted 2026-08-02** |
| `0008` | `PCI: imx6: Provide a clock to the device for i.MX8MQ` (anatop writes) | blocker — see problem 2 |
| `0009` | `dt-bindings: pci: fsl,imx6q-pcie: Add extref clock for i.MX8MQ` | **submitted 2026-08-02** |
| `0010` | `arm64: dts: imx8mq: Declare the PCIe extref clock` (5 boards) | **submitted 2026-08-02** |
| `0011`/`0012` | anatop `"syscon"` compatible + binding | only exist to make `0008` work |
| `0015` | phanbell hdmi audio | downstream, untested |
| `0016` | bring-up aid: disables pcie/hdmi/audio | delete when bring-up ends |

Numbering has gaps (`0013`, `0014`); that is pre-existing and fine.

## Verified findings

### 7.2 renamed `drm_atomic_state` to `drm_atomic_commit`

Affects any patch that names the type. Fixed in `0001` (Cadence driver) and in
`packages/linux/patches/rockchip-old/` for RK3288/RK3328/RK3399. Allwinner was
*not* affected — its matches were the `drm_atomic_state_helper.h` filename and a
context line, not the type.

### 7.2 requires `devm_drm_bridge_alloc()`

`drm_bridge_add()` now takes a reference, so the bridge must be refcount
initialised. `0001` embedded `struct drm_bridge` in a `devm_kzalloc()`ed
container, giving:

```
[drm] DRM bridge corrupted or not allocated by devm_drm_bridge_alloc()
refcount_t: addition on 0; use-after-free.
  drm_bridge_get.part.0 / drm_bridge_add / cdns_mhdp8501_probe
```

then a NULL deref. `devm_drm_bridge_alloc()` needs the funcs at allocation time,
but the driver picked them from the connector type parsed later, so the probe was
reordered: a `cdns_mhdp8501_get_connector_type()` helper reads the remote node
from `dev->of_node` first, then the container is allocated with the right funcs.

Verified: `32c00000.bridge` binds, `card1-HDMI-A-1` appears, and with a cable
attached the pipeline reaches a modeset — `[drm] fb0: imx-dcssdrmfb frame buffer
device`.

The bridge driver is **silent on successful probe**; it only has `dev_err()`
paths. Absence of errors proves nothing. Check binding instead:

```sh
ls -l /sys/bus/platform/drivers/cdns-mhdp8501/
```

### pcie0's reference clock and `clk_disable_unused()`

`0008` writes three anatop fields directly:

| register | field | value |
|---|---|---|
| `0x30360074` bits 3:0 | mux `pllout_monitor_sel` | `0xb` = `sys_pll1_out_monitor` |
| `0x30360074` bit 4 | gate `pllout_monitor_clk2` | 1 |
| `0x3036007c` bits 2:0 | divider `sys_pll1_out_monitor` | 7 = /8, 800 → 100 MHz |

All three are **registered clocks** — see `drivers/clk/imx/clk-imx8mq.c:389,394,395`.
Nothing holds a reference on the gate, so `clk_disable_unused()` switches it off
whenever it runs *after* the driver has set it. The endpoint then has no
reference clock, its LTSSM sits in POLL.Active, and the port reports:

```
imx6q-pcie 33800000.pcie: Device found, but not active
```

(That string is `dw_pcie_wait_for_link()` in `pcie-designware.c`, meaning the
link partner is detected electrically but never trains.)

Whether it races depends on probe order. Observed directly:

```sh
devmem 0x30360074 32     # 0x0B = mux+divider survived, CKE cleared
devmem 0x3036007c 32     # 0x07
```

`clk_disable_unused()` gates clocks; it does not rewrite mux or divider values,
which is exactly the pattern seen.

### `f98c2dfedb73` broke the anatop syscon in 2022

`arm64: dts: imx8m: align anatop with bindings` (Peng Fan, 2022-09) dropped
`"syscon"` from the anatop node:

```
-  anatop: syscon@30360000 {
-    compatible = "fsl,imx8mq-anatop", "syscon";
+  anatop: clock-controller@30360000 {
+    compatible = "fsl,imx8mq-anatop";
```

`syscon_node_to_regmap()` calls `device_node_get_regmap(np, of_device_is_compatible(np, "syscon"), true)`,
so with no `"syscon"` it returns `-EPROBE_DEFER` and `0008` logs

```
imx6q-pcie 33800000.pcie: Couldn't configure the internal PLL as REF clock
```

and does nothing. The Coral patches date from March 2023 and were written against
a tree that still had it, which is why they worked then and silently stopped.
`0011`/`0012` restore it. Confirmed: the message disappears and pcie0 links.

Note `of_syscon_register()` uses `of_iomap()` and does not `request_mem_region()`,
so the syscon regmap coexists with the clk driver's mapping of the same node.

### ath10k firmware was never installed for aarch64

`ath10k/*` appears only in `packages/linux-firmware/kernel-firmware/firmwares/x86_64.dat`.
Added `projects/NXP/devices/iMX8/config/kernel-firmware-any.dat`.

**`kernel-firmware` did not rebuild when that file was added.** `calculate_stamp()`
(`config/functions`) hashes only `$PKG_DIR`, the project/device `patches/` and
`packages/` directories, and `PKG_NEED_UNPACK` — not `config/kernel-firmware*.dat`,
even though `makeinstall_target()` reads them. Fixed by adding the lists to
`PKG_NEED_UNPACK`. This was latent for Amlogic, Rockchip and Samsung too.

Keep the whole `ath10k/QCA6174/hw3.0/*` directory. A trimmed list is fragile: the
part reports no subsystem ids, so `board-2.bin` cannot match it —

```
failed to fetch board data for bus=pci,vendor=168c,device=003e,subsystem-vendor=0000,subsystem-device=0000
board_file api 1 bmi_id N/A crc32 ed5f849a
```

— and it falls back to the generic `board.bin`. That message is expected, not a
defect.

**ath10k without firmware is not benign on this board.** A failed probe leaves the
device in D3cold; the driver then retries against an inaccessible device, each
register access times out at -110, CPUs stop answering NMI, RCU stalls, and boot
never completes. Do not enable pcie0 without the firmware present.

## Open problems

### 1. Enabling dcss stops pcie0 linking - RESOLVED

This is the clock-gating race described above, nothing more. Enabling the
display shifts probe order so that `clk_disable_unused()` runs *after* `0008`
writes anatop instead of before, and the CLK2_P/N gate is switched off.

Evidence, all on the same build:

- dcss off: 4/4 boots link pcie0
- dcss on: 0/5, with `devmem 0x30360074 32` reading `0x0B` - CKE cleared
- dcss on plus `clk_ignore_unused`: everything works at once - both PCIe ports
  link, ath10k loads firmware, and the HDMI framebuffer comes up

Symptoms when it fails:

```
imx6q-pcie 33800000.pcie: Device found, but not active
pci 0000:00:00.0: removing 2.5GT/s downstream link speed restriction
pci 0000:00:00.0: retraining failed
pci 0000:00:00.0: bridge configuration invalid ([bus 00-00]), reconfiguring
```

`clk_ignore_unused` is a global workaround. The narrow fix is to hold a
reference on the gate by naming `IMX8MQ_CLK_MON_CLK2_OUT` as pcie0's `pcie_bus`
clock, replacing the `IMX8MQ_CLK_DUMMY` placeholder, so
`clk_bulk_prepare_enable()` keeps it on. That keeps `0008`'s register writes, so
it changes one thing rather than two - unlike the attempt in problem 2.

### 2. Describing the reference clock in DT does not work

Attempted (and reverted in `0501b138e0`): drop `0008`, put
`IMX8MQ_CLK_MON_CLK2_OUT` in pcie0's `clocks` so `clk_bulk_prepare_enable()`
holds a reference, and set mux and rate with `assigned-clocks`. This is what the
clk framework is for and would delete `0008`, `0011` and `0012`.

It produces the correct hardware state and still does not work:

```
devmem 0x30360074 32  -> 0x1B      # mux 0xb, CKE set
devmem 0x3036007c 32  -> 0x07      # /8

/sys/kernel/debug/clk/clk_summary:
  sys1_pll_out              6 6  800000000  Y
    sys_pll1_out_monitor    1 1  100000000  Y
      pllout_monitor_sel    1 1  100000000  Y
        pllout_monitor_clk2 1 1  100000000  Y   pcie@33800000
```

Tested with dcss off and without `clk_ignore_unused` — the configuration where
`0008` links every time — and pcie0 stayed at `Device found, but not active`.

Ruled out: clock gating (`clk_disable_unused()` ran after the link check in that
boot), dcss (disabled), `hard-wired` (not referenced in `pci-imx6.c`), and
ordering. `imx_pcie_host_init()` runs

```
assert_perst(true) -> regulators -> clk_enable -> assert_core_reset
  -> init_phy -> phy_init -> phy_power_on -> deassert_core_reset
  -> assert_perst(false)
```

so the bulk clock enable is *earlier* than `0008`'s write in `init_phy()`, and
both are well before PERST# is released.

So `0008` does something the DT description does not, and what that is has not
been established. Until it is, `0008` stays and the phanbell pcie0 patch cannot
go upstream.

Next step, rather than more guessing: instrument `0008` to read the three fields
back at the end of `imx8mq_pcie_init_phy()` and again at link-check time, then
diff a working boot against a rework boot. If they match at both points, the
clock is not the differentiator at all.

### 3. Smaller ones

- `platform cpufreq-dt: deferred probe pending: (reason unknown)` — cpufreq never
  comes up.
- `imx-hdmi hdmi_audio: cpu dai phandle missing or invalid` / `-22` — predates all
  of this, will resurface when `0015` is enabled.
- `of_irq_parse_pci: failed with rc=134` — 134 is not an errno; seen once, on the
  boot that then locked up on ath10k. Watch for it.

## Testing

### Bring-up switches

`0016` appends `status = "disabled"` for pcie0, pcie1, mhdp, dcss, hdmi_audio,
sound-hdmi and sai1 at the end of the phanbell dts, so they win over the earlier
enables. Delete a block to re-enable one device.

Faster: flip them in u-boot with no rebuild. `bootle.scr` already does `fdt addr`
and `fdt resize`:

```
setenv fdt_addr 0x43000000
setenv bootargs 'rw console=ttymxc0,115200 earlycon=ec_imx6q,0x30860000,115200 ignore_loglevel boot=/dev/mmcblk0p1 disk=/dev/mmcblk0p3 ssh net.ifnames=0 pci=pcie_bus_perf debugging progress debug=all rootwait'
ext2load mmc 0:1 ${loadaddr} KERNEL
ext2load mmc 0:1 ${fdt_addr} imx8mq-phanbell.dtb
fdt addr ${fdt_addr}
fdt resize
fdt set /soc@0/pcie@33800000 status okay
fdt set /soc@0/pcie@33c00000 status okay
booti ${loadaddr} - ${fdt_addr}
```

Node paths: `/soc@0/pcie@33800000`, `/soc@0/pcie@33c00000`,
`/soc@0/bus@32c00000/bridge@32c00000`, `/soc@0/bus@32c00000/display-controller@32e00000`.

The bridge will not probe unless the display controller is enabled too — the two
have a DT dependency cycle and mhdp simply defers.

Rebuild `bootle.scr` with the toolchain's mkimage:

```sh
tail -c +65 bootle.scr > bootle.txt        # strip the 64-byte uImage header
build.LibreELEC-iMX8.aarch64-13.0-devel/toolchain/bin/mkimage \
    -A arm64 -O linux -T script -C none -d bootle.txt bootle.scr
```

### Serial console

**The console going quiet is not a hang.** `packages/sysutils/busybox/scripts/init:887`
does `echo '1 4 1 7' > /proc/sys/kernel/printk`, so from initramfs onward only
ALERT/EMERG reach the console. Several apparent "hangs" during this work were
just this. Add `ignore_loglevel` to keep everything printing; it cannot be undone
by a later write to `/proc/sys/kernel/printk`.

Also drop `keep_bootcon` and `console=tty0` — with both consoles plus earlycon on
the same UART, output stopped very early in a way that looked exactly like an
early-boot hang while the kernel was in fact running fine and reachable over ssh.

If the console dies anyway, the image has `ssh` on the cmdline; the board is
usually still up and `dmesg` tells the whole story.

## Upstream

Submitted 2026-08-02, against mainline. Awaiting review.

1. **`PCI: imx6: Avoid dereferencing a NULL clock name`** (`0005`) — sent
   standalone to linux-pci. `of_clk_bulk_get()` leaves `clk_bulk_data::id` NULL
   when `clock-names` is shorter than `clocks`; the extref scan added by
   `d8574ce57d76` dereferences it. Carries `Fixes:` and `Cc: stable` — the buggy
   commit is in v7.0 and v7.1, not v6.19, so v7.0 is the first affected release.
   Reasoned from the source: this board's `clock-names` is complete, so the path
   has never been exercised here.

2. **extref for i.MX8MQ** — a 3-patch series with a cover letter, extending
   Richard Zhu's i.MX95 work in `d8574ce57d76`:
   - 1/3 `dt-bindings: pci: fsl,imx6q-pcie: Add extref clock for i.MX8MQ` (`0009`)
   - 2/3 `PCI: imx6: Select the PCIe REF_CLK source on i.MX8MQ` (`0007`)
   - 3/3 `arm64: dts: imx8mq: Declare the PCIe extref clock` (`0010`)

   **2/3 must not land before 3/3**: the driver change alone silently drops
   `REF_USE_PAD` on every existing i.MX8MQ board, because they all describe their
   oscillator as `pcie_bus`, which nothing looks up by name. The reverse order is
   safe. Boards touched: evk, kontron-pitx-imx8m, mnt-reform2, tqma8mq-mba8mx,
   zii-ultra — all untested, no access to the hardware. Endpoint nodes were left
   alone: all disabled, separate binding.

   The series spans two trees — 1/3 and 2/3 are PCI, 3/3 is i.MX DTS — which the
   cover letter calls out along with the ordering constraint.

   Validated on pcie1: `clock-names` ends in `extref`, link up Gen2, TPU
   enumerated.

   `0007` was reauthored before sending. Nothing of the original downstream patch
   survives the rebase onto `enable_ext_refclk`, so carrying Ryosuke Saito's and
   Khem Raj's `Signed-off-by` would have asserted they certified a patch neither
   had seen.

3. **`arm64: dts: imx8mq-phanbell: enable PCIe`** — not sent. Blocked on open
   problems 1 and 2.

Drop each patch from the tree once its upstream version lands.

Note for the next series: `checkpatch` reports four `code indent should use tabs
where possible` errors in `imx8mq-zii-ultra.dtsi`. That file aligns continuation
lines with tab+spaces where the other four use tab+tab+space; the added lines
match each file's local style, so checkpatch flags them while the identical lines
directly above pass unexamined.

`0001` and everything depending on it stays downstream: it is NXP's out-of-tree
driver, not something that can be sent anywhere as-is.
