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

Display, both PCIe ports and wifi all come up together with no kernel command
line workaround, since `0006` holds a reference on the CLK2_P/N gate. Audio is
the one piece not yet enabled — see problem 3.

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
| `0015` | phanbell hdmi audio | dead — `0001` has no audio driver, see problem 3 |
| `0016` | bring-up aid: disables pcie/hdmi/audio | delete when bring-up ends |
| `0017` | phanbell rt5645 analog audio via `simple-audio-card` | needs `0018`, see problem 3 |
| `0018` | `ASoC: rt5645: Make the Kconfig symbol user selectable` | to submit to alsa-devel |

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

Fixed in `0006` by naming `IMX8MQ_CLK_MON_CLK2_OUT` as pcie0's `pcie_bus` clock,
replacing the `IMX8MQ_CLK_DUMMY` placeholder, so `clk_bulk_prepare_enable()`
holds a reference and the gate cannot be switched off. `0008`'s register writes
are kept, so this changes one thing rather than two.

Confirmed: with the display enabled and no `clk_ignore_unused`,
`clk: Disabling unused clocks` runs, both ports link, and ath10k loads firmware.

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

Narrowed since: holding the reference on its own works (see problem 1), so the
failure is in the other half - replacing the register writes with
`assigned-clocks`. One difference not yet ruled out is *when* the mux is
switched. `assigned-clocks` sets it at probe, before the gate is enabled;
`0008` sets it in `init_phy()`, after `clk_bulk_prepare_enable()` has already
turned the gate on. The next experiment is to add `assigned-clocks` back on top
of the working configuration, keeping `0008`, and only then remove the writes.

Next step, rather than more guessing: instrument `0008` to read the three fields
back at the end of `imx8mq_pcie_init_phy()` and again at link-check time, then
diff a working boot against a rework boot. If they match at both points, the
clock is not the differentiator at all.

### 3. Audio — HDMI audio has no driver; the analog path is the reachable one

Nothing is enabled: `0016` disables `sai1`, `sound-hdmi` and `hdmi_audio`, so a
current boot ends with

```
ALSA device list:
  No soundcards found.
```

and `aplay -l` agrees.

#### HDMI audio cannot work today — do not bother enabling `0015`

`0001` is Sandor Yu's MHDP8501 v2 series, and its own cover text says so:

```
- Audio driver are removed from the patch set, it will be add in another
  patch set later.
```

The Kconfig hunk still carries `select DRM_CDNS_AUDIO` — a symbol that exists
nowhere in 7.2-rc5 and is not added by the patch, so the select is dangling and
does nothing.

That is fatal for `0015`, because `sound/soc/fsl/imx-hdmi.c` does not talk to
the bridge directly. It hardcodes its codec side:

```c
data->dai.codecs->dai_name = "i2s-hifi";
data->dai.codecs->name = "hdmi-audio-codec.1";
```

`hdmi-audio-codec` is `HDMI_CODEC_DRV_NAME` (`include/sound/hdmi-codec.h:138`),
the generic `hdmi-codec` platform device that a *display* driver is supposed to
register on the machine driver's behalf. Nothing on this board registers one,
so the codec component never appears and `devm_snd_soc_register_card()` never
completes. No card, no matter what the DT says.

(The `.1` suffix is a `PLATFORM_DEVID_AUTO` instance number, so even once an
audio driver exists, hardcoding `.1` is fragile.)

So HDMI audio is blocked on the follow-up MHDP8501 audio patch set, not on
anything in our tree. Check whether that series has been posted before spending
more time here.

While looking, other things about `0015` worth knowing:

- `sound-hdmi` sets `protocol = <0>` and a seven-entry `constraint-rate` list.
  Upstream `imx-hdmi.c` parses neither — only `audio-cpu`, `hdmi-out`/`hdmi-in`
  and `model`. Downstream leftovers.
- `hdmi_audio` is a *second* `fsl,imx-audio-hdmi` node with `model =
  "imx-hdmi"`, the property spelled `hdmi_out` (underscore, so it is not the
  `hdmi-out` the driver looks for) and **no `audio-cpu` at all**. That is the
  node behind the historic `imx-hdmi hdmi_audio: cpu dai phandle missing or
  invalid` / `-22`. It is scaffolding; delete it.
- `audio-cpu = <&sai1>` contradicts the commit message, which says *"Uses SAI4
  for HDMI output … Uses SAI4"* twice. The one-pin pinctrl
  (`MX8MQ_IOMUXC_SAI1_TXFS_SAI1_TX_SYNC`) is also wrong for an internal path to
  the HDMI TX. Unresolved, but moot until there is a driver.
- No mainline freescale board uses `fsl,imx-audio-hdmi` at all.

#### The analog path — `0017`, awaiting a first boot

Both devices are on the bus, confirmed on hardware:

```
# i2cdetect -y -r 2        (i2c3)
10: -- ... 1a --           rt5645 codec
30: -- ... 3d --           ptn5150 USB-C controller
```

`0017` describes the codec with `simple-audio-card`: rt5645 on `&i2c3` at
`0x1a`, `&sai2` enabled with `fsl,sai-mclk-direction-output`, and a
`pinctrl_sai2` group. The board facts come from the reverted commits, the
mechanism from mainline.

What was carried over from the reverted patches and what was dropped:

- Kept: `interrupt-parent = <&gpio5>`, `interrupts = <4 IRQ_TYPE_EDGE_BOTH>`,
  `hp-detect-gpios = <&gpio5 4 …>`, `realtek,dmic1-data-pin = <2>`,
  `realtek,jd-mode = <0>`. The doubled-up irq/gpio on the same line is correct:
  `rt5645.c:4254` requests the i2c irq as the edge trigger and `:3244` reads the
  level through `gpiod_hp_det` when `jd_mode == 0`.
- Dropped `clocks = <&clk IMX8MQ_CLK_SAI2_ROOT>` / `clock-names = "mclk1"` —
  `rt5645.c` has no `devm_clk_get` at all, so those were inert.
- Dropped `realtek,jd-invert` and `realtek,jd-low-volt-enable` — the driver only
  reads `in2-differential`, `dmic1-data-pin`, `dmic2-data-pin` and `jd-mode`
  (`rt5645.c:3939`). Mendel-kernel properties.
- Dropped `google,edgetpu-audio-card` entirely for `simple-audio-card`.
- `#sound-dai-cells = <0>` selects `rt5645-aif1`: `snd_soc_get_dlc()` maps
  `args_count == 0` to `id = 0`, i.e. `dai_drv[0]`.

Only the SAI2 *transmit* clocks are muxed (MCLK, TXFS, TXC, TXD0) plus RXD0.
That relies on `fsl_sai` leaving `RCR2.SYNC` set by default — `fsl_sai.c:905-907`
writes `TCR2.SYNC` from `synchronous[TX]` and `RCR2.SYNC` from
`synchronous[RX]`, and the default is `RX = true, TX = false`, so receive takes
its clocks from transmit. That is what a codec with one BCLK/LRCK pair needs.
Note the in-code comments here are misleading and `fsl,sai-synchronous-rx` does
the *opposite* of what its name suggests; go by the register writes.

Pad settings are `0xd6` on all five, copied from `imx8mq-mnt-reform2.dts:323`,
the one in-tree i.MX8MQ board with a SAI2 group.

**Not verified — needs a schematic before this can go upstream:**

- `avdd-supply` / `cpvdd-supply` are **required** by
  `realtek,rt5645.yaml` and are omitted, because which BD71837 rail feeds them
  is unknown. `devm_regulator_bulk_get()` will fall back to dummy regulators and
  log `supply avdd not found, using dummy regulator`, so it still probes.
- No `widgets` / `routing` yet. HPOL/HPOR almost certainly reach the jack and
  the board has a 4-pin speaker terminal that SPOL/SPOR would drive, but that
  is not confirmed, so nothing is asserted. Add them once `amixer` shows what
  the codec actually exposes.
- Whether SAI2_MCLK is physically routed to the codec. The reverted patch named
  `IMX8MQ_CLK_SAI2_ROOT` as the codec's `mclk1`, which implies it is, and
  `mclk-fs = <256>` assumes so.

**First boot result: the codec driver was not built.** The only line the whole
log produced was

```
platform sound-analog: deferred probe pending: asoc-simple-card: parse error
```

with no `rt5645` message anywhere. `SND_SOC_RT5645` is a **promptless** Kconfig
symbol (`sound/soc/codecs/Kconfig:1858` — contrast `SND_SOC_RT5640` directly
above it, which has one). Nothing can turn it on:

- the only `imply` is from `SND_SOC_ALL_CODECS`, which is `depends on
  COMPILE_TEST` and therefore absent from any real config;
- every driver that `select`s it is x86 (`intel/boards`, `amd`), MediaTek or
  Rockchip — all machine drivers, none usable here.

So an i.MX8MQ board using `simple-audio-card` cannot build the codec at all,
even though the part has its own binding. `0018` gives the symbol a prompt and
the config enables it plus the `RL6231` helper it pulls in
(`default y if SND_SOC_RT5645=y`). Worth submitting to alsa-devel.

The "parse error" itself is `asoc_simple_parse_dai()` failing to resolve
`sound-dai = <&rt5645>` — with no component registered for that node,
`snd_soc_get_dlc()` returns `-EPROBE_DEFER` and simple-card reports it through
`dev_err_probe()`.

Checks after the next boot:

```sh
dmesg | grep -iE 'rt5645|sai|simple-audio|asoc'
aplay -l
amixer -c 0 scontrols
speaker-test -c2 -twav -l1
```

If it stops the board booting, back it out at u-boot without a rebuild:

```
fdt set /sound-analog status disabled
fdt set /soc@0/bus@30800000/sai@308b0000 status disabled
```

Still to do on the analog side: the 40-pin header (`simple-audio-card` on
`&sai1` against a `linux,snd-soc-dummy` codec — both halves are upstream), and
`typec_ptn5150` at `0x3d` (`nxp,ptn5150a`, irq `gpio3` line 0), which is a real
Coral device but a separate concern from audio.

The SAI1 ownership conflict between the two designs is not live: HDMI audio
cannot claim SAI1 until it has a driver, and when that driver arrives it will
settle the SAI4 question itself.

#### SAI address map (7.2-rc5 `imx8mq.dtsi`, all `status = "disabled"`)

| label | node path |
|---|---|
| `sai1` | `/soc@0/bus@30000000/sai@30010000` |
| `sai6` | `/soc@0/bus@30000000/sai@30030000` |
| `sai5` | `/soc@0/bus@30000000/sai@30040000` |
| `sai4` | `/soc@0/bus@30000000/sai@30050000` |
| `sai2` | `/soc@0/bus@30800000/sai@308b0000` |
| `sai3` | `/soc@0/bus@30800000/sai@308c0000` |

Note the numbering is not address order and there is no `sai@30020000`.

### 4. Smaller ones

- `platform cpufreq-dt: deferred probe pending: (reason unknown)` — **fixed,
  awaiting a boot.** `CONFIG_MFD_ROHM_BD718XX=y` but
  `# CONFIG_REGULATOR_BD718XX is not set`, so the PMIC registered its pwrkey
  child (`bd718xx-pwrkey` at 9.79s in the log) and no regulators. phanbell gives
  all four A53s `cpu-supply = <&buck2>`, so `dev_pm_opp_set_regulators()` →
  `regulator_get_optional(cpu_dev, "cpu")` deferred forever
  (`cpufreq-dt.c:186-192`). The reason is blank because `dev_err_probe()` is
  called on `cpu0`, not on the `platform cpufreq-dt` device the timeout message
  walks — and `-EPROBE_DEFER` prints at debug level regardless. Enabling
  `CONFIG_REGULATOR_BD718XX=y` is also what makes DVFS *safe*: buck2 is
  constrained to 850000-1000000 and this speed grade selects the 900000 and
  1000000 operating points, so without the driver the core voltage is just
  whatever u-boot left. Confirm with `cat
  /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies` — expect
  1000000 and 1500000 (see the OPP note below).
- OPP filtering on this board, for reference. `imx-cpufreq-dt` reports
  `supported-hw 0x8 0x1` (speed grade 3, market segment 0) and
  `a53_opp_table` in `imx8mq.dtsi` masks each entry as
  `opp-supported-hw = <grade>, <market>`:

  | OPP | masks | selected |
  |---|---|---|
  | 800 MHz | `<0xf>, <0x4>` | no — market `0x4 & 0x1 = 0` (industrial only) |
  | 1000 MHz | `<0xe>, <0x3>` | yes |
  | 1300 MHz | `<0xc>, <0x4>` | no — industrial only |
  | 1500 MHz | `<0x8>, <0x3>` | yes |

  So two operating points, 1.0 and 1.5 GHz. The table is not the problem.
- `of_irq_parse_pci: failed with rc=134` — 134 is not an errno; seen once, on the
  boot that then locked up on ath10k. Not seen since; watch for it.
- `ath10k_pci: failed to fetch board data for … subsystem-vendor=0000,
  subsystem-device=0000 from ath10k/QCA6174/hw3.0/board-2.bin` — then
  `board_file api 1`. It falls back to `board.bin` and the radio works; the
  QCA6174 on this board reports a null subsystem ID so it can never match a
  board-2.bin entry. Cosmetic.
- No bluetooth HCI device appears. The QCA6174 is a combo part with BT on a
  UART; nothing in the DT describes it. Not investigated.

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
`/soc@0/bus@32c00000/bridge@32c00000`, `/soc@0/bus@32c00000/display-controller@32e00000`,
`/soc@0/bus@30000000/sai@30010000` (sai1), `/sound-hdmi`, `/hdmi_audio`.

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
