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

pcie0 negotiates Gen1 (`fsl,max-link-speed = <1>`), pcie1 Gen2. `imx8mq.dtsi`
sets `<2>` on both controllers, so pcie0's `<1>` is our override and pcie1
inherits the base value.

**That override matches the endpoint rather than throttling it**, which was worth
checking because it is not stated anywhere in the datasheet - the only basis on
record was "the vendor Mendel image does the same". `max_link_speed` in sysfs
settles it:

| device | max | current |
|---|---|---|
| `0000:00:00.0` pcie0 root port | 2.5 GT/s | 2.5 GT/s |
| `0000:01:00.0` QCA6174 | 2.5 GT/s | 2.5 GT/s |
| `0001:00:00.0` pcie1 root port | 5.0 GT/s | 5.0 GT/s |
| `0001:01:00.0` Edge TPU | 5.0 GT/s | 5.0 GT/s |

The QCA6174 advertises 2.5 GT/s as its own capability, so Gen1 is all it can do.
Note the root port row proves nothing on its own: dwc rewrites the root port's
`LNKCAP` from `fsl,max-link-speed` (`pci-imx6.c:1023`), so it only ever reports
back what the devicetree told it. The endpoint row is the evidence.

Keep the property rather than dropping it: without it pcie0 would inherit `<2>`,
and `pci-imx6.c:1023` would program a Gen2 target speed and attempt a speed
change that can only fall back.

Mendel binds `hif_pci` (Qualcomm's out-of-tree qcacld) to the wifi; we use
upstream `ath10k`, which wants entirely different firmware.

## Current state

Working: display, both PCIe ports, ath10k wifi, bluetooth, cpufreq, and both
audio cards.

```
card 0: Analog [Coral Analog],   device 0: sai-tx-rx-rt5645-aif1 rt5645-aif1-0
card 1: HDMI   [Coral HDMI],     device 0: sai-tx-rx-i2s-hifi i2s-hifi-0
card 2: Header [40-pin Header],  device 0: sai-tx-rx-dit-hifi dit-hifi-0
```

**The card indices are not stable across boots.** A later boot came up with them
the other way round, Header as card 0 and Analog as card 1. Neither
`simple-audio-card` instance has a fixed index, so whichever probes first takes
card 0, and that depends on when its SAI and codec become available — which
already varies by seconds between boots depending on when `imx-sdma` loads.

Consequence: anything selecting `hw:0`, `default` or "card 0" gets a different
device from one boot to the next, and one of the two is a dummy `spdif-dit`
with nothing attached. Refer to them by name — `hw:CARD=Analog,DEV=0` — which
is stable.

In practice Kodi is fine, because `aplay -L` exposes both by name and that is
what its ALSA sink enumerates:

```
default:CARD=Analog     Coral Analog, sai-tx-rx-rt5645-aif1 rt5645-aif1-0
default:CARD=HDMI       Coral HDMI, sai-tx-rx-i2s-hifi i2s-hifi-0
default:CARD=Header     40-pin Header, sai-tx-rx-dit-hifi dit-hifi-0
```

The exposure is to anything hardcoding an index — `amixer -c 0` already caught
us out, returning nothing because card 0 happened to be the dummy that boot.
`0025` and `0026` add a third card and make the ordering worse. Worth deciding
whether the header card earns its place on a media appliance at all, given it
has no codec and destabilises the numbering; that is the only thing `0014` buys.

### Analog audio - WORKING. It was never a hardware, devicetree or driver fault

Resolved on hardware. Both channels, clean 440 Hz. The card was correct
throughout - **two** things were missing, and each alone leaves it silent with
everything measuring right:

1. **No mixer initialisation.** The DAC-to-headphone path is muted at Realtek's
   power-on defaults and nothing unmutes it: `simple-audio-card` sets no mixer
   state and the DAPM switches along the path are user controls defaulting off.
   Fixed by a `soundconfig` stanza, `b07e398f62`.
2. **No initial jack detect.** `rt5645_jack_detect()` force enables the `LDO2`
   and `Mic Det Power` supplies that `HP amp` depends on, and programs
   `RT5645_CHARGE_PUMP` away from its `0x0c06` reset value. The only initial
   detect is the `rt5645_irq(0, rt5645)` at the end of
   `rt5645_set_jack_detect()`, which needs a machine driver -
   `simple-audio-card` has none. So state is only ever sampled from an edge on
   `hp-detect-gpios`, and a headphone already in the socket at boot is never
   noticed. Fixed by `0014`, `1a5c9410ec`. Confirmed by the one observation that
   distinguishes it: a clean boot now plays with the rt5645 IRQ count still at
   **0** in `/proc/interrupts`, i.e. no jack edge ever happened and the probe did
   the detect itself.

Point 2 is why the mixer fix appeared to stop working after a reboot: the
session that first produced sound had the jack replugged at some point, which
silently supplied the missing half. With `b07e398f62` alone, a fresh boot gives
`/proc/interrupts` rt5645 count 0, register `091: 0c06`, and silence; a replug
takes the count odd and `091` to `0e06` and the card plays.

The working register state, read from
`/sys/kernel/debug/regmap/2-001a-nocache/registers` *during playback*:

| reg | value | |
|---|---|---|
| `002` | `0808` | `HP_VOL` - mutes (15/7) and channel switch (14/6) all clear |
| `029` | `8080` | `AD_DA_MIXER` - `DAC1` in (14/6 clear), Stereo ADC out (15/7 set) |
| `02a` | `1616` | `STO_DAC_MIXER` - L1→L and R1→R only, no cross-mix |
| `045` | `4000` | `HPO_MIXER` - `HPVOL` in (13 clear), direct `DAC1` out (14 set) |
| `066` | `0c20` | `PWR_VOL` - `PWR_HV_L` and `PWR_HV_R` both up |

Three things made this take far longer than it should have:

- **`0xc8c8` in `HP_VOL` *is* the reset default.** The note that used to be here
  claimed `0x2a` and `0x45` were "unmuted" and read the DAPM widget states as
  confirmation. A DAPM widget reading `On` proves the path is *powered*, not that
  the mixer switches along it are open. Comparing each register against its
  entry in `rt5645_reg[]` would have found this on day one.
- **The `HP_VOL` mutes are AUTODISABLE controls on the `HPOVOL` widget.** So the
  obvious route - `DAC 1 → HPO MIX` via `HPO MIX DAC1 Switch` - leaves the amp
  muted no matter what you set, because with the `HPOVOL` branch idle DAPM
  re-asserts the mute bits. The path has to go `DAC L1 → HPOVOL MIXL → HPOVOL →
  HPO MIX` so the branch is powered. That also puts the headphone volume control
  in circuit, which the direct switch bypasses.
- **Turning every switch on is not a safe probe.** It produced a loud squeal that
  looked like success but was not the DAC at all: `029` read `4040`, i.e. bit 14
  set (`DAC1` **off**) and bit 15 clear (Stereo ADC **on**). `RECMIXL HPOL` /
  `RECMIXR HPOR` route the headphone output back into the record mixer, so with
  the ADC into `DAC1 MIX` the loop oscillates. The tone was never getting
  through.

**Mendel being silent was never evidence.** Its mixer is also all-off while
playing - every `HPO`, `SPK`, `SPOL`, `SPOR`, `LOUT`, `OUT MIX` and `PDM`
switch - so its audio comes from a userspace UCM or PulseAudio profile a bare
root shell does not load. Same root cause, different distro.

Still true and worth keeping: SAI2 TX runs at 1.536 MHz for 16 bit and 3.072 MHz
for 24 bit, 2 slots, I2S framing, FIFO non-empty; and the SAI1/SAI2 pinmuxes are
byte for byte the board's own, decoded from `vendor.dts` against
`imx8mq-pinfunc.h`.

Useful things confirmed by the vendor dump:

- `Headphone Jack` (read-only) reads `on`, so the vendor's jack detect sees the
  headphones. Our muxed pad reads `hi` with `GPIO_ACTIVE_HIGH`, the same sense,
  which confirms `fe8d4c3aba`. `snd_soc_rt5645.quirk=520` inverts that and must
  not be used.
- `RT5645 IF1 DAC1 L/R Mux` are `Slot0`/`Slot1` on the vendor. We never set
  those; worth checking our defaults if this is ever revisited.

**But the jack is not dead, and the first version of this note was wrong to
imply it.** Before `fe8d4c3aba` the board produced an audible click in both ears
at the end of a stream. A click means the headphone amp was driving the phones,
so the jack, the amp and the cable all work. What the click actually was is
jack-detect flapping on the unmuxed pad: the jack-out path in
`rt5645_jack_detect()` writes `RT5645_HP_VOL` `L_MUTE|R_MUTE` on a live amp, and
that is what was audible. Once the pad was muxed the reading became stable, the
transitions stopped, and so did the clicks.

So the output stage reaches the headphones, and the fault is that the DAC's
output never arrives at `HPO MIX`, or the DAC is not converting. Note that a
DAPM path reading `On` with non-zero in/out proves topology, not signal.

Every configuration assumption is confirmed by the board documentation, not
just by inference from the vendor devicetree. The Coral Dev Board block diagram
and datasheet give:

- codec **ALC5645**, which is Realtek's product name for the RT5645, so
  `compatible = "realtek,rt5645"` is right
- codec attached to **`SA2/I2S`**, so SAI2 is right
- the **3.5 mm jack** carrying **"HPO and MIC"** - a 4-conductor CTIA headset
  jack off the headphone outputs - so routing `Headphone Jack` from
  `HPOL`/`HPOR` is right
- a separate **4-pin stereo terminal**, which would be the Class-D SPO outputs
  and is not what a headphone is plugged into

So the devicetree is not the problem, which matches everything measuring
correct.

The planned isolation test - a CTIA headset's microphone through `BST1` ->
`HPOVOL MIXL` -> `HPOVOL` -> `HPO MIX` -> `HP amp` -> `HPOL`, entirely analog -
was never needed. Enabling `HPOVOL MIXL DAC1` for a different reason (to power
the branch so the AUTODISABLE mutes would clear) opened the DAC path through the
same mixer and the card played. The earlier ADC-to-DAC loopback attempt was
silent for the same reason everything else was: the mutes downstream of it were
still asserted.

One digital-side assumption also remains unverified: the pinmux matches the
board's pad list, but nothing has confirmed the SAI2 TX pin actually toggles.

Two real defects did come out of the investigation and are fixed: the unmuxed
hp-detect pad (`fe8d4c3aba`) and HDMI audio programming N/CTS with no active
mode (`78357d8fcc`).


### HDMI audio

Working: `speaker-test -D default:CARD=HDMI` is audible and Kodi's GUI sounds
play. Two things had to be right, and neither announced itself:

- **The audio InfoFrame has to be sent explicitly.** An HDMI sink stays muted
  until it sees one. Registering `hdmi_write_audio_infoframe` on the bridge is
  not enough — `drm_atomic_helper_connector_hdmi_update_audio_infoframe()` is
  exported *for drivers to call*, and nothing in the DRM core calls it for you,
  so the write callback is simply never reached. The symptom is the worst kind:
  the stream runs to completion with correct timing and no error at any layer.
  vc4 and it66121 both call it at the tail of their prepare callback.
- **sai4 needs 32 bit slots.** `hdmi-codec` advertises 24 bit, and with no slot
  width set `fsl_sai_hw_params()` takes it from the sample width, asking for
  `48000 * 2 * 24` = 2.304 MHz. `fsl_sai_set_bclk()` only accepts even dividers
  and 24.576 MHz / 2.304 MHz is 10.67, so `hw_params` returns `-EINVAL` and Kodi
  retries twice a second forever. 32 bit slots give 3.072 MHz, a ratio of 8.
  This is what NXP's own `imx-hdmi.c` does (`cpu_priv.slot_width = 32`) and it
  matches the `TRANS_SMPL_WIDTH_32` the bridge writes to `AUDIO_SRC_CNFG`.

**With no sink attached**, Kodi opens the card anyway and the character rate is
zero, so the N/CTS lookup has nothing to work with. Two things were wrong about
the first attempt at this, both now fixed:

- Returning `-ENODEV` from `prepare` made it far worse, not better. ASoC logs a
  failed `snd_soc_dai_prepare()` at *error* level and Kodi retries the open
  forever, so six quiet messages became an unbounded flood of roughly ten lines
  a second. `78357d8fcc`'s claim of being "confirmed on hardware" was measured
  with no display attached and no Kodi retry loop running; it does not hold.
- Caching the rate at `atomic_enable` is the wrong place to read it from. After
  a hotplug the display came up at 171.9 s and the errors were still arriving at
  210 s, i.e. the cached value stayed zero through a modeset, so audio after a
  hotplug would have been misprogrammed.

`prepare` now reads `connector->state->hdmi.tmds_char_rate` directly, treats no
state as no mode, skips the `CM_I2S_CTRL` N/CTS write when the rate is zero and
does not warn about a zero rate. Nothing fails, nothing is misprogrammed and
nothing is logged. `hdmi.char_rate` is gone from `struct _hdmi_data`.

What remains with no sink is `hdmi-audio-codec: HDMI: Unknown ELD version 0` -
hdmi-codec parsing an all-zero ELD because there is no sink. That is the DRM
core's message, not ours. It could be avoided by implementing
`hdmi_audio_startup` and rejecting there, which fails the open rather than the
prepare — but that puts the retry loop back, so leave it.

**The HDMI fix is verified on hardware (7.2-rc6, build 20260804153445, which
does not carry the rt5645 slot-width fix).** A boot with no sink attached, the
case that used to flood, now logs exactly two lines of audio noise:

```
[   20.419777] hdmi-audio-codec hdmi-audio-codec.5.auto: HDMI: Unknown ELD version 0
[   20.435084] hdmi-audio-codec hdmi-audio-codec.5.auto: HDMI: Unknown ELD version 0
```

and nothing else — no `-19` at `snd_soc_dai_prepare()` and no `pixel clock 0 kHz`
warning. The ELD message does not repeat either: because `prepare` now succeeds,
Kodi's open succeeds and it stops retrying, so the core's message fires twice
during device enumeration and never again. Kodi then streams into a bridge with
no sink, which is harmless — with a zero character rate the N/CTS write is
skipped, so nothing is misprogrammed.

**The rt5645 slot-width fix is NOT verified by that boot, and the absence of
`failed to derive required Tx rate: 2304000` from it is not evidence.** The
analog flood was only ever reachable because HDMI `prepare` was failing: Kodi
kept cycling devices and hit sai2 on every pass. Now that HDMI opens on the
first try, Kodi settles there and never touches the analog card, so the bug is
latent rather than fixed in that build.

The reproducer, which does not involve Kodi at all:

```sh
speaker-test -D default:CARD=Analog -F S24_LE -c 2 -t sine -f 440
```

Note `-F` for the format; `-f` is the sine frequency, and passing a format name
to it silently clamps to 30 Hz and leaves the default `S16_LE` in place, which
has always worked and so tests nothing. With `S24_LE` and no slot width pinned:

```
Stream parameters are 48000Hz, S24_LE, 2 channels
Unable to set hw params for playback: Invalid argument
```

with one `fsl-sai 308b0000.sai: failed to derive required Tx rate: 2304000` in
`dmesg`. That is `fsl_sai_set_bclk()` rejecting the 10.67 divider, isolated from
device cycling.

**Verified on build 20260804154545, which carries `0010`:** the same command
reaches `hw_params` and runs, `was set period_size = 8191`, cycling through
Front Left and Front Right. So 32 bit slots do satisfy the divider at 24 bit,
and `rt5645_hw_params()` not writing a BCLK-to-frame ratio on AIF1 means the
codec does not object to the padding. Both audio log floods are now closed.

At the time this was measured the card still made no sound, which was the
pre-existing mixer problem and unrelated to the slot width - the SAI now accepts
the format it always should have, and that is all this fixes. The silence itself
was resolved separately; see the analog audio section above.

The N/CTS table only knows the seven CTA rates (25200/27000/54000/74250/148500/
297000/594000 kHz). Every mode we care about is in it, but an odd one such as
1024x768@60 logs `pixel clock … is not in the N table` and falls back to the
594000 entry, which will sound wrong.

The header card on sai1 had the same 24 bit bug and failed identically while
Kodi was cycling devices; it went quiet once Kodi settled on HDMI rather than
being fixed. `0009` now pins 32 bit slots there too, which also lets 16 bit
through since 1.536 MHz divides 24.576 MHz evenly as well.

### 44.1 kHz - fixed, and it was one missing property

Every card failed on 44.1 kHz content:

```
fsl-sai 308b0000.sai: failed to derive required Tx rate: 2822400
```

Not an `aplay` artefact - Kodi hit it too, on HDMI
(`30050000.sai`, `sai-tx-rx-i2s-hifi`).

Two patches were needed:

- `869864bf5a` names `AUDIO_PLL1_OUT` and `AUDIO_PLL2_OUT` as `pll8k`/`pll11k`
  on sai1, sai2 and sai4, so `fsl_asoc_reparent_pll_clocks()` can pick the
  family matching the requested rate, and adds `mclk-fs` to the header and HDMI
  cards. Necessary but on its own it changed nothing.
- `1896dce677` adds **`system-clock-direction-out`** to each card's cpu dai.
  This is the one that mattered:

```c
/* simple_util_parse_clk() */
if (of_property_read_bool(node, "system-clock-direction-out"))
	simple_dai->clk_direction = SND_SOC_CLOCK_OUT;
```

Absent the property `clk_direction` stays 0, which is `SND_SOC_CLOCK_IN`, and
`simple_util_hw_params()` passes it straight to `snd_soc_dai_set_sysclk()`.
`fsl_sai_set_dai_sysclk()` opens with `if (dir == SND_SOC_CLOCK_IN) return 0`,
so it returned immediately every time - the mclk rate was never set and the
reparent was never reached. Silently, with no error, at every rate.

**Verified on hardware.** Both cards open 44.1 kHz natively -
`exact rate : 44100` straight to the hardware, no resampling - and 48 kHz still
works. The reparent is visible during a 44.1 kHz stream:

```
audio_pll2_out   1  1  ...  722534397  ...  Y   30010000.sai   pll11k
   sai2          1  1  ...   11289600  ...  Y
audio_pll1_out   0  0  ...  786431998  ...  N   30010000.sai   pll8k
```

`sai2` is at 44100 * 256 off PLL2 at /64, with PLL1 idle. Before `1896dce677`
the mclk was frozen at 24576000 whatever was asked for.

The tell that the mclk was never being set, and which should have been checked
much earlier: `sai2` sat at exactly 24.576 MHz during 32 kHz *and* 48 kHz
playback, where `mclk-fs = 256` asks for 8.192 and 12.288 MHz. A rate that never
moves at any sample rate is not a divider problem.

Two theories were checked against the source and discarded on the way here, both
recorded because each looked convincing:

- *`sai*_root_clk` is a gate without `CLK_SET_RATE_PARENT`, so the rate cannot
  propagate to the `sai2` mux.* Wrong: `__imx_clk_hw_gate2()` passes
  `flags | CLK_SET_RATE_PARENT` unconditionally.
- *The node is missing `mclk0`, which `imx8mq-evk.dts` declares.* Wrong:
  `fsl_sai` always assigns `mclk_clk[0]` from `mclk_clk[1]` or `bus_clk`
  (`fsl_sai.c:1600`).

Neither would have been caught without reading the actual source; the first was
asserted by a summary of `clk-imx8mq.c` and is the kind of thing that nearly
became a kernel patch.

Also settled along the way, and no longer needed: ALSA's own
linear-interpolation converter does bridge 44.1 to 48 kHz correctly, via a
`/run/asound.conf` defining a `plug` with a fixed slave rate. That was the
fallback plan and is now unnecessary, since the hardware clocks 44.1 kHz
natively.

### The DMICs record silence, and two theories are dead

The board has both microphones - the block diagram shows MIC 1 and MIC 2
71 mm apart, U3/U4 are `SPK0415HM4H-B` PDM parts on sheet 5 with no `_DNP`
marking, and a photograph confirms `OSC1` really is unpopulated where the
schematic marks it `_DNP`, so those markings are reliable. `arecord` still
captures silence.

Everything measurable on the path is correct, checked during capture:

| reg | value | |
|---|---|---|
| `027` | `5840` | ADC2 switches on, ADC1 off, ADC2 source = DMIC |
| `062` | `8000` | `PWR_ADC_S1F`, the stereo1 ADC filter, powered |
| `075` | `a488` | `DMIC_1_EN` set, data pin field `00` = GPIO5 |
| `0c0` | `4080` | `GP2_PIN_DMIC1_SCL` set, `GP5_PIN_DMIC1_SDA` set |

**Theory 1, the binding enum, is a real bug but not the cause.** The two
enums in `rt5645.h` are named backwards relative to their use: the switch on
`pdata.dmic1_data_pin` accepts `IN2N`/`GPIO5`/`GPIO11` (1/2/3) from the enum
named `RT5645_DMIC2_*`, while `realtek,dmic1-data-pin` is documented in the
binding with the *other* set, `IN2P`/`GPIO6`/`GPIO10`/`GPIO12`.
`rt5645_parse_dt()` reads the property straight in with no remapping, so the
binding's enum is simply wrong for that property. Our `= <2>` therefore
selects GPIO5, and `075` confirms the driver programmed exactly that. Worth
sending as a documentation fix regardless.

**Theory 2, the I2S2 pin mux, is disproven.** `0c0` bit 4,
`I2S2_DAC_PIN_GPIO`, reads clear even though the GPIO5 case in
`rt5645_i2c_probe()` writes it, and the register cache cannot explain it -
the default table has `{ 0xc0, 0x0000 }`. A debug patch re-asserted the bit
at the end of the component probe, the `dev_info` proved the code ran, and
the register still read `4080`. The bit is not settable on this part, so it
was never the explanation.

**The pin choice is confirmed correct.** Sheet 5 zoomed in shows `DMIC_DAT`
landing on **pin 32, `DACDAT2`**, and the driver's GPIO5 case is precisely
the one that repurposes that pin: it sets `I2S2_DAC_PIN_GPIO` so the I2S2
DAC pin becomes a GPIO, then `GP5_PIN_DMIC1_SDA`. So "GPIO5" and "DACDAT2"
are the same ball, and `realtek,dmic1-data-pin = <2>` is right. The vendor
value was never the problem.

Which puts all the weight on that one bit. `0c0` reads `4080`: bit 14
`GP2_PIN_DMIC1_SCL` set, bit 7 `GP5_PIN_DMIC1_SDA` set, bit 4
`I2S2_DAC_PIN_GPIO` clear. Those are the first and third writes of the
GPIO5 case landing and the second failing, and they are consecutive
`regmap_update_bits()` calls, two of them into the same register. Nothing
explains that in software: `GPIO_CTRL1` is in `readable_register()` rather
than `volatile_register()` so it is cached normally, the only reset after
probe is in `i2c_shutdown()`, and no DAPM widget or mixer control uses bit
4. So either the hardware does not implement that bit on this part, or
something clears it at runtime after probe. Reading `0c0` immediately after
boot, before any stream has run, separates the two.

Note the analog microphone through `IN1P` is silent too, and that cannot be
a `GPIO_CTRL1` problem. Two silent capture sources sharing only ADC ->
`Stereo1 ADC MIXL` -> `IF_ADC1` -> `RT5645 IF1 ADC Mux` -> AIF1TX -> SAI2 RX
is better explained by one fault in that shared path than by two unrelated
front-end faults, so that is the more promising thread of the two.

### The capture path is muted at reset, exactly like the playback path was

The reason both microphones recorded silence was not the front ends at all.
Every capture mixer is muted out of reset, so DAPM could never complete a
path and never powered the ADC. Reading `061` during a capture showed
`PWR_ADC_L`/`PWR_ADC_R` clear, and the codec state was byte for byte the
same during `arecord` as during playback - the capture stream changed
nothing.

Two registers said it plainly and had been sitting in earlier dumps:

| reg | reset | meaning |
|---|---|---|
| `03c`/`03e` | `007f` | REC_L2/R2_MIXER, all seven sources muted |
| `027` | `7060` | ADC1 and ADC2 muted on both L and R |

Unmuting them brings the whole chain up:

```sh
amixer -c Analog sset 'RECMIXL BST1' on
amixer -c Analog sset 'RECMIXR BST1' on
amixer -c Analog sset 'Sto1 ADC MIXL ADC1' on
amixer -c Analog sset 'Sto1 ADC MIXR ADC1' on
amixer -c Analog sset 'IN1 Boost' 3
```

after which, during a capture, `064` reads `8804` (`PWR_BST1`, `PWR_MB1`),
`065` reads `0c02` (both record mixers) and `061` reads `8306`
(`PWR_ADC_L`/`PWR_ADC_R`). Nothing in the chain is unpowered. This is the
same class of bug as the playback path being muted at reset, which
`b07e398f62` fixed for the DAC to headphone chain; the capture side was
never looked at.

### The capture path now powers, and the headset mic is still silent

Unmuting the record mixer and the ADC1 branch fixes a real bug but does not
produce audio. What is verified, from registers read during an open capture:
`064` reads `8804` so `PWR_BST1` and `PWR_MB1` are on, `065` reads `0c02` so
both record mixers are on, and `061` reads `8306` so both ADCs are on. Before
the unmute none of that happened - the codec state during `arecord` was byte
for byte its state during playback. So the DAPM path completes now and did
not before.

`arecord -V stereo` still shows a flat `00%|00%` meter with `IN1 Boost` at 8,
which is 52 dB. Nothing is reaching the ADC.

Everything checkable says it should. The jack is a Singatron TRRS wired to
CTIA and sheet 5 states the pinout outright: tip left, ring 1 right, ring 2
ground, **sleeve microphone**. `HP_MIC` comes off the sleeve through FB12
into `IN1P_HP_MIC` and lands on the codec's pin 11, which Realtek merely
*names* `IN1P_RING2`. `MICBIAS1` reaches the same node through R23 2.2K with
R159 100K to ground. The same headset enumerates as a headset microphone on a
Windows PC, so the part is good and is the right type. An earlier guess that
the board was OMTP was wrong.

The codec agrees with the silence rather than with the schematic:
`rt5645_jack_detect()` reads `IN1_CTRL3 & 0x7`, treats 1 or 2 as
`SND_JACK_HEADSET` and anything else as `SND_JACK_HEADPHONE`, and reads
**4** - with `00a` bit 2 confirming `CBJ_BST1_EN` was enabled for the
measurement. That was dismissed once on the grounds that it only sets
`jack_type` and drops `Mic Det Power` while `BST1` powers anyway, which is
true but beside the point: two independent measurements, the codec's and the
level meter, both say nothing is on the pin.

The next measurement is physical, not more register reading. `TP19` sits
directly on `IN1P_HP_MIC`, so a meter there reads the bias: roughly half of
`MICBIAS1` with a working mic across it, near `MICBIAS1` if the connection is
open, near zero if it is shorted to ground. That distinguishes a jack or
connection fault from anything in the codec, and nothing else will.

### The 24 bit slot width is a property of the SAI, not of any codec

The analog card had the same bug and it went unnoticed for longer, because the
board is normally used with a display and Kodi settles on HDMI. Booting with no
sink makes both cards flood at once: `-EINVAL` from `fsl_sai_hw_params()` with
`failed to derive required Tx rate: 2304000`, several times a second, forever.
`0010` now pins 32 bit slots as well, so all three cards say the same thing.

That is the right shape for the fix. The constraint is `fsl_sai_set_bclk()`
rejecting odd dividers off a 24.576 MHz root, so it applies to every card on
this SoC regardless of what is on the far end — a spdif-dit stand-in, an
rt5645, or the MHDP bridge. Checked before assuming it was safe for the rt5645:
`rt5645_hw_params()` computes `bclk_ms` from the frame size but only writes it
for AIF2 (`RT5645_I2S_BCLK_MS2`). Our card is on AIF1, which gets only
`I2S_PD1` and the data-length bits, so the codec takes the width from its own
register and ignores the padding — no ratio for the padding to disagree with.

Consequence worth recording: **the analog card has never been exercised at
24 bit.** Every test that reached the hardware was `speaker-test`, which is
`S16_LE`, and 1.536 MHz divides evenly, so 16 bit always got through. Kodi never
got past `hw_params` on it at all. So this is not the explanation for the
analog silence — it is the explanation for why Kodi could not even try.

Display, both PCIe ports and wifi come up together, and **the kernel command
line now carries no workarounds at all** — `clk_ignore_unused` went when `0006`
took a reference on the CLK2_P/N gate, and `regulator_ignore_unused` went when
`0019` marked buck3 `regulator-always-on`. Verified on hardware:

```
# ls /proc/device-tree/…/pmic@4b/regulators/BUCK3/
regulator-always-on  regulator-boot-on  regulator-min-microvolt  …

# grep '^ buck3' /sys/kernel/debug/regulator/regulator_summary
 buck3      use 1   open 0   900mV
```

`use 1, open 0` is enabled with no consumer — held up by the constraint alone,
which is the whole point. buck4 reads the same, confirming that dropping the
VPU counterpart cost nothing.

Not finished:

- **Thermal throttling has never actually engaged.** `cpufreq-cpu0` exists and
  `0024` cleared the last bind failure, but nothing has driven the board to
  75 °C since, so the passive path is present rather than proven. See problem 5.
- **The `kodi.target` lockup is fixed but not explained.** Handing buck3 to
  `pgc_gpu` killed the board silently in six of thirteen boots; removing that
  one property gave five clean boots in a row. Why the handoff fails here when
  `imx8mq-librem5.dtsi` does the same thing and works is unknown. Problem 4.
- **Problem 2 is closed.** `0031`–`0033` are deleted, the pcie0 reference clock
  is described in `0011` with `assigned-clocks`, and nothing writes a clock
  controller's registers from a PCI driver any more. The phanbell pcie0 patch
  is upstreamable.
- **The lockup detectors** (`13f13f1d7b`) were added to chase the hang and are
  no longer needed. Revert before this config goes near master.

A note on reading these boots: `deferred probe pending` at ~10 s is the
`deferred_probe_timeout` report, not a verdict. Both SAIs and both cards appear
in it on a slow boot because `imx-sdma` loads as a module afterwards; probing
resumes when it does, and the cards come up. Check `aplay -l`, not the log.

## Patches

| patch | what | status |
|---|---|---|
| | **0001–0004 — submitted upstream 2026-08-02; `0002`–`0004` awaiting a direction from Frank Li** | |
| `0001` | `PCI: imx6: Avoid dereferencing a NULL clock name` | sent standalone |
| `0002` | `dt-bindings: pci: fsl,imx6q-pcie: Add extref clock for i.MX8MQ` | series 1/3 |
| `0003` | `PCI: imx6: Select the PCIe REF_CLK source on i.MX8MQ` | series 2/3; needs a v2 - clearing `REF_USE_PAD` when `"extref"` is absent breaks existing devicetrees, and the replacement shape is Frank's call |
| `0004` | `arm64: dts: imx8mq: Declare the PCIe extref clock` (5 boards) | series 3/3 |
| `0005` | `ASoC: rt5645: Make the Kconfig symbol user selectable` | **in mainline** `588852647b81` (2026-08-08); drop on the next kernel bump |
| | **0006–0010 — v2 posted to the imx list 2026-08-08** | |
| `0006` | Keep the GPU rail on | fixes `buck3: disabling`, problem 4 |
| `0007` | Do not hardcode a cooling state that may not exist | **ready**; fixes the trip 3 bind failure |
| `0008` | Enable i2c2 and i2c3 | **ready**; depends on nothing. Rates and pad config both corroborated by `/flash/vendor.dts`: i2c2 and i2c3 at `0x186a0` (100 kHz), i2c1 at `0x61a80` (400 kHz), and `i2c2grp`/`i2c3grp` pad config `0x4000007f` |
| `0009` | Mux the 32 kHz reference clock pad | **ready**; depends on nothing |
| `0014` | `ASoC: rt5645: Perform the initial jack detect at probe` | **submitted** to ASoC 2026-08-06; no in-tree board meets its two conditions, so it is a no-op upstream |
| `0010` | rt5645 analog audio via `simple-audio-card` | **working** (needs the `soundconfig` mixer state, `b07e398f62`); needs `0005` and `0008` |
| | **0011–0012 — blocked behind `0003`** | |
| `0011` | Enable pcie0 and pcie1, with the VPH rail and `reg_wlan` | needs `0003`; carries the monitor clock description |
| `0012` | QCA6174 Bluetooth on uart2 | **working**; needs `0011` for `reg_wlan` |
| `0013` | 40-pin header I2S card on SAI1 | **working**; weakest of the set, keep local — and last, so it never blocks a prefix |
| | **0021–0030 — imported HDMI stack** | |
| `0021` | Cadence MHDP8501 HDMI/DP driver (Sandor Yu, ~6600 lines) | downstream only; needed three 7.2 fixes |
| `0022`–`0024` | evk / pico-pi / phanbell DCSS + HDMI enablement | downstream, needs `0021` |
| `0025` | HDMI audio for MHDP8501 via `DRM_BRIDGE_OP_HDMI_AUDIO` | **working**; fills the gap v1 left, to submit |
| `0026` | phanbell HDMI audio card on SAI4, 32 bit slots | **working**; needs `0025` |

The whole set applies to pristine 7.2-rc5 with no fuzz and no offsets.
`0008`-`0013` were rebuilt for upstream in `3d25559614`; see `PATCHES.md` for
what was dropped and why.

## Verified findings

### 7.2 renamed `drm_atomic_state` to `drm_atomic_commit`

Affects any patch that names the type. Fixed in `0001` (Cadence driver) and in
`packages/linux/patches/rockchip-old/` for RK3288/RK3328/RK3399. Allwinner was
*not* affected — its matches were the `drm_atomic_state_helper.h` filename and a
context line, not the type.

### 7.2 deprecates `system_wq`

`cdns_mhdp8501_irq_thread()` in `0001` queues its hotplug debounce with
`mod_delayed_work(system_wq, ...)`, which 7.2 flags the first time the HDMI
hotplug interrupt fires:

```
workqueue: work func hotplug_work_func enqueued on deprecated workqueue.
Use system_{percpu|dfl}_wq instead.
```

`include/linux/workqueue.h:465` marks `system_wq` `__WQ_DEPRECATED` — "use
system_percpu_wq, this will be removed" — and `workqueue.c:2286` warns once per
call site. `system_percpu_wq` is the exact equivalent, not a behaviour change:
`schedule_delayed_work()` now queues there itself (`workqueue.h:856`).

Third 7.2 fix to this imported series, after the `drm_atomic_commit` rename and
the `devm_drm_bridge_alloc()` conversion.

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

**The subsystem ids cannot be fixed, and do not need to be.** They are read
straight out of the card's PCI config space — `ath10k/pci.c:3626` copies
`pdev->subsystem_vendor` and `pdev->subsystem_device` into `ar->id`, and
`ath10k_core_create_board_name()` (`core.c:1595`) formats them into the
board-2.bin lookup key. This module simply does not have them programmed, so
there is nothing for software to set.

Three reasons not to chase it:

- The message is `ath10k_err` (`core.c:1545`), which is why it reads like a
  failure, but the very next thing the code does is fall back to `board.bin`,
  and that succeeds — hence `board_file api 1` on the following line.
- **The real calibration is not in the board file anyway.** Our log says
  `cal otp`, i.e. `ATH10K_CAL_MODE_OTP` (`core.h:876,897`) — the chip's own OTP.
  A board-2.bin match would supply board data, not calibration.
- There is no Coral entry to match against. ath10k *does* offer
  `qcom,ath10k-calibration-variant` (`core.c:1167-1170`), which appends
  `,variant=<x>` to the same key, but the base still contains
  `subsystem-vendor=0000,subsystem-device=0000`, so it only helps once
  linux-firmware carries a matching entry. Nobody can produce one from the
  vendor either: Mendel binds `hif_pci` (qcacld), not ath10k, so no ath10k board
  data for this module exists.

Using the variant property would also mean adding a DT node for the PCI device
under the root port, since ath10k reads it from `ar->dev->of_node`.

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

### 2. Describing the reference clock in DT - RESOLVED

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

**The vendor programs exactly the same values.** Read from Mendel on this board:

```
0x30360074 = 0x0000001b     mux 0xb = sys_pll1_out_monitor, gate bit 4 set
0x3036007c = 0x00000007     divider /8, 800 -> 100 MHz
```

That is bit-for-bit what `0008` writes and what our working configuration ends
up with, so the register-level programming was never in doubt, and problem 2 is
purely about *how* to express it. Note the vendor kernel is NXP BSP derived and
does the same direct register writes — there is no vendor precedent for a DT
description, so nothing to copy. `0008` is not a hack relative to the vendor;
it is the same design. It is still the wrong shape for upstream, since a PCI
controller driver has no business writing a clock controller's registers.

**And the vendor's clock framework does not know these clocks exist.**
`grep -iE 'monitor|pcie' vendor-clk.txt` on Mendel returns only pcie entries —
there is no `pllout_monitor_sel`, no `pllout_monitor_clk2`, no
`sys_pll1_out_monitor` anywhere in its `clk_summary`.

That explains the entire history of this bug. The NXP BSP the Coral patches came
from never registered those three anatop fields as clocks, so nothing could gate
them and raw register writes stuck permanently. Mainline `clk-imx8mq.c:389,394,395`
*does* register them, which is what let `clk_disable_unused()` reclaim the gate
out from under the PCIe driver.

So the patches were not wrong when written; the ground moved. It also means
there is no "correct" vendor DT description to copy — holding a reference from
`0006` is our own answer and appears to be the right one.

For reference, the vendor's PCIe clock rates, which ours should match:

```
pcie1_phy  / pcie2_phy    100000000
pcie1_aux  / pcie2_aux     25000000
pcie1_ctrl / pcie2_ctrl   250000000
```

**Likely answer, found by reading the revert back rather than by more boots.**
The rework wrote this on `&pcie0`:

```dts
assigned-clocks = <&clk IMX8MQ_CLK_MON_SEL>,
                  <&clk IMX8MQ_CLK_MON_SYS_PLL1_DIV>;
assigned-clock-parents = <&clk IMX8MQ_CLK_MON_SYS_PLL1_DIV>;
assigned-clock-rates = <0>, <100000000>;
```

A property set in a `&label` override **replaces** the whole property; it does
not add to it. `imx8mq.dtsi:1831` already sets `assigned-clocks` on that node:

```dts
assigned-clocks = <&clk IMX8MQ_CLK_PCIE1_CTRL>,
                  <&clk IMX8MQ_CLK_PCIE1_PHY>,
                  <&clk IMX8MQ_CLK_PCIE1_AUX>;
assigned-clock-parents = <&clk IMX8MQ_SYS2_PLL_250M>,
                         <&clk IMX8MQ_SYS2_PLL_100M>,
                         <&clk IMX8MQ_SYS1_PLL_80M>;
assigned-clock-rates = <250000000>, <100000000>, <10000000>;
```

so the rework deleted all three — including `pcie1_phy`, which the controller
takes its PHY reference from. None of the evidence gathered at the time rules
that out: `clk_summary` was only ever read for the monitor subtree, and that
subtree was configured correctly in *both* the working and the failing boot,
which is precisely why it looked as though the register writes were doing
something extra.

`0035` lists all five assignments so nothing is dropped. Cross-checked against
`clk-imx8mq.c`: `MON_SYS_PLL1_DIV` is the divider at anatop `0x7c[2:0]` off
`sys1_pll_out` (line 389), `MON_SEL` the mux at `0x74[3:0]` (394),
`MON_CLK2_OUT` the gate at `0x74[4]` (395) — the same three fields `0033`
pokes — and `sys_pll1_out_monitor` is index 11 in `pllout_monitor_sels`, so the
mux value the framework writes is the same `0xb`. `hard-wired`, which the
rework also dropped, is read by nothing in the PCI or DWC code.

Tested in two steps. **Step 1 — `0035` in, `0033` still in — links every time**,
both ports, ath10k and the Edge TPU both enumerating. The reference snapshot
from that boot, which is the data this problem always lacked:

```
pcie1_ctrl              1 1  250000000  Y
   pcie1_root_clk       1 1  250000000  Y   pcie@33800000
pcie1_phy               1 1  100000000  Y   pcie@33800000
pcie1_aux               1 1   10000000  Y   pcie@33800000
sys_pll1_out_monitor    1 1  100000000  Y
   pllout_monitor_sel   1 1  100000000  Y
      pllout_monitor_clk2 1 1 100000000 Y   pcie@33800000

0x30360074 = 0x0000001B     0x3036007c = 0x00000007
```

The three `pcie1_*` rates are the values `imx8mq.dtsi` intends, preserved
because `0035` lists all five assignments. The anatop registers are bit for bit
what `0033` writes, and each bit has an independent source in `0035`: `MON_SEL`'s
parent gives `0x74[3:0] = 0xb`, `MON_SYS_PLL1_DIV`'s rate gives `0x7c[2:0] = 7`,
and `MON_CLK2_OUT` in `clocks` gives `0x74[4]` through
`clk_bulk_prepare_enable()`. So `0033` is now rewriting values that are already
correct.

**Step 2 — `0033` deleted — links too.** `PCIe Gen.1 x1 link up` on pcie0,
`Gen.2` on pcie1, ath10k and the Edge TPU both enumerating, and the snapshot
above reproduced *byte for byte*: same rates, `0x74 = 0x1B`, `0x7c = 0x07`, with
no code anywhere in the kernel writing those registers. The clock framework does
the whole job.

So the premise this problem rested on for a month was wrong. The register writes
never did anything an `assigned-clocks` description could not; the earlier
rework simply deleted three assignments it did not realise it was overwriting,
and the one piece of evidence that would have shown it — the `pcie1_*` rates —
was never captured, because attention was on the monitor subtree that was
correct in both cases.

`0031`, `0032` and `0033` are all gone, and the description now lives in the
pcie0 node in `0011`. anatop is back to plain `"fsl,imx8mq-anatop"`, which means
`f98c2dfedb73` was never a regression to work around: the clock driver owning
those registers is exactly what makes the description work.

**The folded form was booted too**, and reproduces the same snapshot a third
time. Three configurations, byte-identical clock state and anatop registers in
all of them:

| | `0033` writes | description | result |
|---|---|---|---|
| step 1 | yes | `0035` tail block | links |
| step 2 | no | `0035` tail block | links |
| shipped | no | in the pcie0 node in `0011` | links |

Which is the whole argument: the register writes were redundant, and moving the
description into the node changed nothing.

### 3. Audio — HDMI audio has no driver; the analog path is the reachable one

Nothing is enabled: `0016` disables `sai1`, `sound-hdmi` and `hdmi_audio`, so a
current boot ends with

```
ALSA device list:
  No soundcards found.
```

and `aplay -l` agrees.

#### What the vendor OS actually has

```
card 0: edgetpuaudiocar [edgetpu-audio-card], device 0: Coral Edge TPU HiFi rt5645-aif1-0
card 1: Header [40-pin Header], device 0: 30010000.sai-snd-soc-dummy-dai snd-soc-dummy-dai-0
```

Both cards appear under `aplay -l` *and* `arecord -l`, so the codec does capture
as well as playback. Three things settled:

- **The part at `0x1a` is a real rt5645 and uses `aif1`.** That is `dai_drv[0]`,
  so `0017`'s `#sound-dai-cells = <0>` selects the right DAI.
- **SAI1 belongs to the 40-pin header**, not to HDMI — card 1's cpu DAI is
  `30010000.sai`, which is `sai1`. The reverted 2024 patch had this right and
  `0015` has it wrong.
- **There is no HDMI audio card on the vendor OS either.** Only two cards, and
  neither is HDMI. So `0015`'s `sound-hdmi` never worked on this board even
  downstream, which matches the MHDP audio driver having been dropped from the
  patch set.

**SAI2 confirmed for the codec**, and the vendor boot log says it in words:

```
edgetpu-audio-card sound-rt5645: clock set to 24576000
edgetpu-audio-card sound-rt5645: rt5645-aif1 <-> 308b0000.sai mapping ok
asoc-simple-card sound-header: snd-soc-dummy-dai <-> 30010000.sai mapping ok
```

The second line is `0017`'s pairing and the third is `0021`'s, including the
`asoc-simple-card` driver itself — so both patches describe what the vendor
describes.

One difference worth remembering if the analog output sounds wrong: the vendor
sets a **fixed** 24.576 MHz sysclk, while `0017` uses `mclk-fs = <256>`, which
gives 12.288 MHz at 48 kHz and scales with rate. Both are legitimate; if rt5645
turns out to want a fixed MCLK, drop `mclk-fs` and set
`system-clock-frequency = <24576000>` on the codec instead.

Supporting detail from `/sys/kernel/debug/asoc/`:

```
platforms:  308b0000.sai  30010000.sai  snd-soc-dummy  dummy-dai
dais:       308b0000.sai  30010000.sai  rt5645-aif2  rt5645-aif1
            i2s-hifi  snd-soc-dummy-dai  snd-soc-dummy-dai
```

`308b0000` is SAI2 and `30010000` is SAI1, so the codec is on SAI2 and the
header on SAI1 — exactly the split `0017` and the reverted patch assume. The
SAI2 half of the audio work is therefore validated against the vendor.

One extra thing that list reveals: **`i2s-hifi` is present**, which is the
`hdmi-codec` DAI (`sound/soc/codecs/hdmi-codec.c`). So the vendor's MHDP driver
*does* register an `hdmi-audio-codec` component — the codec half of HDMI audio
exists there — but no card in `aplay -l` uses it, so the machine link was never
wired up. The "Uses SAI4 for HDMI output" in `0015`'s commit message looks like
a plan that was never finished. Our `0001` has no audio driver at all, so we do
not even have the codec.

**Recommendation: delete `0015` rather than repair it.** It has no working
codec to bind to, its second `hdmi_audio` node is the source of the historic
`-22`, and its claim on SAI1 is simply wrong. Adding the header card
(`simple-audio-card` on `&sai1` against a `linux,snd-soc-dummy` codec, both
upstream) would then be free. `0016` references `&hdmi_audio` and `sound-hdmi`
to disable them, so it has to be adjusted at the same time.

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

**Answered by the schematic**, `google-coral/electricals`,
`dev_board/Coral-Dev-Board-baseboard-schematic.pdf`, sheet 5 *AUDIO: Codec,
Mics & Jack* and sheet 10 *Power Diagram*:

- `avdd-supply` / `cpvdd-supply` are **required** by `realtek,rt5645.yaml` and
  are omitted, so `devm_regulator_bulk_get()` falls back to dummy regulators.
  Sheet 5 bypasses `ANALOG_1v8`, `AVDD`, `CPVDD` and `DACREF` as one group, and
  `ANALOG_1v8` is `V1V8` through ferrite FB3. Sheet 10 shows `V1V8 (BB_1V8)`
  coming from a **baseboard dual DC-DC, an AP3427M off `DCDC_5V`** - *not* from
  the BD71837 on the SOM. So there is genuinely no PMIC rail to point at, which
  is why both our tree and the vendor OS show `2-001a` under `regulator-dummy`.
  The earlier guess that the supplies are hardwired was right. For upstream the
  correct description is a `regulator-fixed`, always-on, named for the rail:
  `MICVDD` comes from `ANALOG_3v3`/`BB_3V3` off the same AP3427M, `DBVDD` from
  `V3V3` and `SPKVDD` from `DCDC_5V`, but only avdd and cpvdd are required.
- **The headset microphone lands on `IN1P`.** J4 pin 5, the sleeve, per the
  CTIA note on the sheet, goes `HP_MIC` -> FB12 -> `IN1P_HP_MIC` -> codec pin
  11 `IN1P_RING2`, biased by `MICBIAS1` through R23 2.2K. rt5645 routes
  `{ "BST1", NULL, "IN1P" }`, which is the BST1 path reasoned about earlier
  from the DAPM graph. The card therefore needs `"IN1P", "Headphone Mic"`;
  without it the microphone is a dead end and only the supply route exists.
- `HPO_L`/`HPO_R` go through R15/R16 33R and FB4/FB11 to J4 pins 4 and 1, tip
  and ring1 - confirming `"Headphone Jack"` from `HPOL`/`HPOR`.
- The `SPDIF_RX` pad is wired to the codec's IRQ pin and annotated *"Used as
  GPIO for IRQ"* on the sheet, which is why GPIO5_IO4 serves as both the codec
  interrupt and `hp-detect-gpios`.
- `SPO_L`/`SPO_R` go to the 4-pin terminal J9, confirming the earlier guess
  that the Class-D outputs drive it and that it is not the headphone path.
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

**Second boot, with `0018`: the driver loads and reaches the chip.** It binds as
`rt5645 2-001a`, takes dummy regulators as expected, and then two boots
disagreed:

- one reported `Device with ID register 0x6308 is not rt5645 or rt5650` at
  ~10.5s;
- the next produced no ID message at all, with the probe starting at 0.316s.

**The error message contradicts the source.** `RT5645_DEVICE_ID` *is* `0x6308`
(`rt5645.c:47`), and the switch at `:4085` has `case RT5645_DEVICE_ID`, so a
read of 0x6308 cannot reach the `default:` arm that prints it. Nothing in our
tree patches `rt5645.c`. Unexplained — do not build on it until a clean
single-boot log settles which behaviour is real.

The "missing supplies caused a bad read" theory is **dead**: the vendor OS gives
the same codec the same two dummy regulators and binds a driver to `2-001a`
successfully. Since `rt5645` is the only driver asking for exactly `avdd` and
`cpvdd`, the part at `0x1a` really is an rt5645/rt5650 and its ID read works
under Mendel. Treat the one failing boot as unexplained until it reproduces.

Note the boot ordering oddity: `rt5645 2-001a` appears *before*
`i2c i2c-2: IMX I2C adapter registered`. That is normal —
`i2c_add_adapter()` registers DT children before the imx driver prints its
banner.

**Third boot: three faults, all now fixed.** Worth recording because two of
them are traps for anyone copying a vendor devicetree.

1. **`micbias1` is a supply widget, so the route direction matters.**

```
Connecting non-supply widget to supply widget is not supported (Headphone Mic -> micbias1)
asoc-simple-card sound-analog: error -EINVAL: parse error
```

`snd_soc_dapm_add_path()` rejects `wsink->is_supply && !wsource->is_supply`
(`soc-dapm.c:621`). The vendor's 4.14 DAPM graph has the pair the other way
round and its kernel allowed it, so copying the direction verbatim broke the
whole card. Correct form is the supply as *source*:
`"Headphone Mic", "micbias1"`.

2. **`linux,snd-soc-dummy` does not exist upstream.** Zero hits in the whole
tree. `sound/soc/soc-utils.c:295` creates the dummy as a *faux device* with no
`of_match_table`, so a devicetree node naming that compatible never binds and
the header card could not resolve its codec. `linux,spdif-dit`
(`spdif_transmitter.c:69`) is the real stand-in and `CONFIG_SND_SOC_SPDIF` was
already on. It is a transmitter, so the header is now **playback only**, where
the vendor's dummy gave both directions.

3. **The bluetooth susclk needed a driver, not a devicetree change.**
`hci_uart_qca serial0-0: failed to acquire clk` and then a deferred serdev.
`clocks = <&pmic>` was right — phanbell already declares the PMIC as a provider
with `#clock-cells = <0>` and `clock-output-names = "pmic_clk"` — but
`CONFIG_COMMON_CLK_BD718XX` was off, so nothing registered the clock and
`devm_clk_get_optional()` returned `-EPROBE_DEFER` forever.
`clk-bd718x7.c:87,133` registers `bd718xx-32k-out` from exactly that parent
property.

Note `0019` was **not** exercised on that boot: `regulator_ignore_unused` was
still on the command line, so the log ends `regulator: Not disabling unused
regulators`. Drop it next time to test the real fix.

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

### 4. `buck3: disabling` costs network access 30s in — `0019`, mechanism unconfirmed

A regression from enabling `CONFIG_REGULATOR_BD718XX`. With real regulators
present the core runs its unused-regulator sweep at the end of init:

```
[   32.057712] buck3: disabling
```

and the board stops answering the network. Observed symptom is **loss of
network, not of display** — the monitor keeps showing an image.

Only two rails on phanbell have a declared consumer at all: `buck2`
(`cpu-supply` on the four A53s) and the fixed `reg_usdhc2_vmmc`. Every other
regulator survives solely because it is marked `regulator-always-on` — and
BUCK3 is the one exception, so it is the only thing the sweep can touch.

**The vendor prints the same line and survives it**, which is the clearest
possible statement of what `0019` fixes:

```
[    6.587235] VSD_3V3: disabling
[    6.599401] buck3: disabling
```

Mendel then goes on to load the GPU driver at 9.53s and run normally. It can,
because there BUCK3 belongs to the GPU power domain: the sweep switches it off
as *currently* unused, and the domain switches it back on when the GPU needs
it. On our tree the rail has no owner at all, so once off it stays off — and it
was already powering a GPU that had been running since boot. Same message, two
completely different meanings.

**BUCK3 is the GPU rail — confirmed from the vendor OS.** `regulator_summary`
under Mendel on the same board:

```
 buck3        0  1  0   900mV  0mA   700mV  1300mV
    gpc_power_domain@4
 buck4        0  2  0  1000mV  0mA   700mV  1300mV
    38300000.vpu
    gpc_power_domain@5
 buck2        0  1  0   850mV  0mA   850mV  1000mV
    cpu0
 ldo7         0  2  0  3300mV  0mA  1800mV  3300mV
    33c00000.pcie
    33800000.pcie
```

BUCK4 lists `38300000.vpu` outright — that is the G1 decoder — so BUCK4 is the
VPU rail and its domain is `@5`. BUCK3's domain `@4` is the GPU, and the vendor
devicetree says so directly rather than by elimination:

```
/boot/vendor.dts:2111:   gpu_pd = "/gpc_power_domain@4";
```

(The unit addresses are the vendor BSP's own numbering; mainline names the same
nodes `pgc_gpu: power-domain@5` and `pgc_vpu: power-domain@6`,
`imx8mq.dtsi:939,948`.)

So `0019` reproduces what the vendor kernel already describes, and matches
`imx8mq-librem5.dtsi:1264` on the other in-tree i.MX8MQ + BD71837 board.
**pico-pi has the same missing line** and would need the same treatment if this
goes upstream.

The exact failure path is still only plausible: DCSS is not in `pgc_gpu`, so the
display keeps scanning out the last frame from DRAM regardless, while etnaviv
GC7000 *is* (`imx8mq.dtsi:1636`) and Kodi renders through it. Losing the rail
mid-render could fault the GPU or take an external abort on an unpowered block
and wedge the kernel — dropping ssh while the screen stays lit, which is the
symptom. Not worth chasing further now that the fix is known to be right.

Two more rails the vendor describes and mainline phanbell does not. Both are
`regulator-always-on` so nothing breaks, but they are under-described:

- `&pgc_vpu { power-supply = <&buck4>; }`
- `vpcie-supply = <&ldo7>` on both `&pcie0` and `&pcie1`

Unblock without a rebuild: add `regulator_ignore_unused` to the kernel command
line (`drivers/regulator/core.c:6855`), the direct analogue of
`clk_ignore_unused`.

### 5. Nothing was throttling the CPU — critical shutdown

Enabling the BD718XX regulator made cpufreq work, and the cores went from
u-boot's 1000 MHz to 1.5 GHz at 1.0 V. Nothing throttled them, and the board
shut down on the critical trip; u-boot reported it on the next power-up:

```
CPU Temperature (94000C) has exceeded alert (85000C), close to critical (95000C)
Critical temperature hit. Shutting down, a power cycle will be necessary
```

**Confirmed on hardware.** `CONFIG_CPU_THERMAL` was off, so `cpufreq_cooling`
never existed:

```
# for d in /sys/class/thermal/cooling_device*; do ...
38000000.gpu   cur=0 max=6
gpio-fan       cur=0 max=1
ath10k_thermal cur=0 max=100
```

Three cooling devices and **no `cpufreq` one**. phanbell's `cpu_alert0` (75 °C)
and `cpu_alert1` (80 °C) maps both name `A53_0`, so both had nothing to bind to
— the entire passive half of the board's thermal design was inert. Only the
65 °C fan trip and the 90 °C critical trip did anything, which is exactly the
path to a shutdown: fan on, no throttling, straight up to critical.

The governor is `ondemand` with LibreELEC's `up_threshold=50`
(`packages/sysutils/systemd/scripts/cpufreq`), and it was observed sitting at a
constant 1500000 kHz at ~62 °C. That is real sustained load, not a pinned
governor — worth chasing separately, since if Kodi is pegging a core at the
idle GUI it may not be rendering through etnaviv.

Fixed with `CONFIG_CPU_THERMAL=y` + `CONFIG_CPU_FREQ_THERMAL=y`, plus
`THERMAL_GOV_BANG_BANG=y` for the active fan trip and `SENSORS_GPIO_FAN=y`
instead of `=m` (as a module it did not load until ~11 s, long after the cores
could be at full speed). Untested as yet — the check is simply whether a
`cpufreq-*` cooling device appears.

Two other things that showed up while measuring:

- **Six trip points, not four.** phanbell's `&cpu_thermal { trips { … } }`
  *adds* to the ones already in `imx8mq.dtsi` rather than replacing them, so
  80 °C passive and 90 °C critical each appear twice. Harmless, but it means
  the board's own numbers are not the whole picture.
- **There are three thermal zones, not one.** The TMU has three sensors and
  `imx8mq.dtsi:289,320,348` gives each its own zone. `sensors` shows them as
  `cpu_thermal_0`, `gpu_thermal_1`, `vpu_thermal_2`. Only `thermal_zone0` is
  the CPU; reading just that one understates the picture.

  | zone | passive | active | critical |
  |---|---|---|---|
  | cpu-thermal | 75 °C + 80 °C → `A53_0` **(was inert)** | 65 °C → gpio-fan | 90 °C |
  | gpu-thermal | 80 °C → `38000000.gpu` | — | 90 °C |
  | vpu-thermal | — | — | 90 °C |

  So the GPU's six-state cooling device *is* wired up — by its own zone's map
  (`imx8mq.dtsi:339`), not by anything in phanbell. The CPU passive path was
  the only broken one.

- **The fan physically works — verified.** Driving it by hand spins it up:

  ```sh
  for f in /sys/class/hwmon/hwmon*/pwm1; do echo 255 > "$f"; done
  ```

  Note the glob has to be in a `for` list: redirection targets are not
  pathname-expanded in busybox ash. `gpio-fan.c:209` maps the pwm value to
  `speed_index = DIV_ROUND_UP(val * (num_speed - 1), 255)`, so 255 is on and 0
  is off. There is no tacho, so the `fan1` RPM reading is the `speed-map` value
  echoed back rather than a measurement — listen for it instead.

  Expected behaviour in service: `fan_toggle0` is 65 °C with `hysteresis =
  <10000>`, so it starts at 65 °C and does not stop until 55 °C. The board idles
  around 61-62 °C, so once it comes on it will mostly stay on. That is the
  hysteresis doing its job rather than a fault.

- **`sensors` reporting the fan as `MANUAL CONTROL` is cosmetic.** gpio-fan sets
  `pwm_enable = true` at probe (`gpio-fan.c:377`) purely so the hwmon `pwm1`
  attribute is writable. `gpio_fan_set_cur_state()` (`:409`) does not consult
  it, so thermal control of the fan is unaffected. `fan1: 0 RPM` at 56 °C is
  correct — its trip is 65 °C.

### 6. Smaller ones

- `platform cpufreq-dt: deferred probe pending: (reason unknown)` — **fixed and
  confirmed on hardware**, `scaling_available_frequencies` now reads
  `1000000 1500000`. `CONFIG_MFD_ROHM_BD718XX=y` but
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
- No bluetooth HCI device appears, because nothing in the DT describes it. This
  is an unclaimed feature rather than a fault, and it is reachable upstream —
  see below.

### 7. Bluetooth — not described, but straightforward to add

The vendor OS has it working:

```
hci0:  Type: Primary  Bus: UART   Manufacturer: Qualcomm (29)
       LMP Version: 4.1 (0x7)  Subversion: 0x25a
Bluetooth: HCI UART protocol QCA registered
```

So it is the QCA6174's BT side on a UART, driven by `hci_qca` over serdev.
Upstream supports the part: `hci_qca.c:2777` matches `qcom,qca6174-bt`, and the
binding is `qcom,qca2066-bt.yaml`, which requires exactly three things —
`compatible`, `clocks` (one 32.768 kHz input) and `enable-gpios`, with an
optional `firmware-name`.

`arch/arm64/boot/dts/mediatek/mt8183-kukui.dtsi:959` is the precedent worth
copying: a **non-Qualcomm** SoC driving a QCA6174 exactly this way.

```dts
&uartN {
	bluetooth {
		compatible = "qcom,qca6174-bt";
		enable-gpios = <&gpioX Y GPIO_ACTIVE_HIGH>;
		clocks = <&pmic>;
		firmware-name = "nvm_00440302.bin";
	};
};
```

**What the vendor devicetree gave us.** It does *not* use serdev — there is no
bluetooth node at all, just an rfkill shim driven from userspace:

```dts
bt_rfkill {
	compatible = "fsl,mxc_bt_rfkill";     /* downstream only */
	bt-power-gpios = <0x38 0x06 0x01>;
	status = "okay";
};
```

Phandle `0x38` is **gpio3**: pcie0's `reset-gpio = <0x38 0x0a 0x01>` in the same
dump is our `<&gpio3 10 GPIO_ACTIVE_LOW>`. So the power line is **gpio3 line 6**.

The UART is **uart2, `serial@30890000`** — it is `status = "okay"` with
`uart-has-rtscts` and a reset, and uart1/`30860000` is the console. Mainline
agrees on the numbering (`imx8mq.dtsi:1151`), which is worth stating because the
i.MX8MQ order is not monotonic: uart1 `30860000`, uart3 `30880000`, uart2
`30890000`, uart4 `30a60000`.

Both original guesses are now settled, and a third thing turned up that the
vendor tree could not have told us.

**Polarity: active high, confirmed indirectly.** The first boot with the clock
in place gave

```
Bluetooth: hci0: setting up ROME/QCA6390
Bluetooth: hci0: Frame reassembly failed (-84)
Bluetooth: hci0: command 0xfc00 tx timeout
```

`-84` is `EILSEQ` — bytes arriving with wrong framing. An unpowered controller
would have given silence and timeouts with no framing errors, so the part is
powered and `GPIO_ACTIVE_HIGH` is right, despite the vendor flagging its own
`bt-power-gpios` `GPIO_ACTIVE_LOW`.

**The clock was a Kconfig problem, not a devicetree one.** `clocks = <&pmic>`
was correct all along — phanbell already declares the PMIC as a provider — but
`CONFIG_COMMON_CLK_BD718XX` was off so nothing registered
`bd718xx-32k-out` (`clk-bd718x7.c:87,133`) and `devm_clk_get_optional()`
deferred forever.

**uart2 has to be reparented off the 25 MHz oscillator.** `hci_qca` declares
`oper_speed = 3000000` (`hci_qca.c:2097`) and `hci_uart_setup()` applies it
immediately after the 115200 init speed (`hci_serdev.c:196-210`). The imx uart
can only reach `uartclk/16`, so on the default parent the host stops at
1.5625 MHz while the controller has already moved to 3 MHz — hence the EILSEQ.
`SYS1_PLL_80M` gives 5 MHz of headroom;
`imx8mq-hummingboard-pulse.dts:112` and `imx8mq-kontron-pitx-imx8m.dts:304`
reparent their uarts the same way, and the vendor uses `SYS1_PLL_160M` for this
same port.

**Firmware: `qca/*00440302*.bin`.** `btqca` builds both names from the
controller version it reads out of the chip — `"qca/rampatch_%08x.bin"` and
`"qca/nvm_%08x.bin"` (`btqca.c:850,944`). The chip answers for itself once the
uart works:

```
Bluetooth: hci0: QCA controller version 0x00440302
Bluetooth: hci0: QCA Downloading qca/rampatch_00440302.bin
```

**An earlier guess of `00130302` was wrong, and the way it was wrong is worth
remembering.** Three things on the vendor OS agreed on it — the
`rampatch_tlv_3.2.tlv` symlink, the byte size of `nvm_tlv_3.2.bin`, and
`HW:QCA6174_REV3_2` in the vendor dmesg. But the first two describe what the
vendor *shipped* under the old downstream driver's naming, and the third came
from the **WLAN** driver, not bluetooth. Three views of the same vendor rootfs
are not three independent confirmations of the hardware.
`mt8183-kukui.dtsi:966`, the precedent already cited for this part, uses
`nvm_00440302_i2s.bin` — the answer was visible from the start.

The firmware list loader `die`s on a pattern that matches nothing
(`kernel-firmware/package.mk:62`), so the wrong glob would have broken the
build rather than leaving bluetooth quiet. It did not, only because the
00130302 files also exist in linux-firmware.

## Testing

### Bring-up switches - retired

There is no longer a disable block at the end of the phanbell dts, and
`bootle.scr` no longer edits the tree: no `fdt set`, no `fdt rm`, and no
`clk_ignore_unused` or `regulator_ignore_unused` on the command line. Every
device comes up from the devicetree as shipped, which also means the PCIe hosts
probe about 0.1s earlier.

Kept for the next time something needs switching without a rebuild, since
`bootle.scr` still does `fdt addr` and `fdt resize`:

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

### Harvesting from the vendor OS

Mendel is dual-bootable on the same eMMC, and it is the only authoritative
description of this board we have. `regulator_summary` from it already settled
the BUCK3/BUCK4 mapping and killed a wrong theory about the codec supplies.
Worth grabbing the rest while it is there. In rough order of value:

**1. The whole vendor devicetree.** Answers most remaining questions at once —
which SAI carries audio, the DAPM routing, whether PCIe uses `vpcie-supply` or
`vph-supply` for LDO7, how bluetooth is wired, the typec node.

```sh
apt install -y device-tree-compiler          # if needed
dtc -I fs -O dts /proc/device-tree > /boot/vendor.dts
# or just take the blob and decompile it elsewhere:
cp /sys/firmware/fdt /boot/vendor.dtb
```

**2. The clock tree.** This is the one that bears on open problem 2 — the PCIe
reference clock that works via `0008`'s register writes but not via an
equivalent DT description.

```sh
cat /sys/kernel/debug/clk/clk_summary > /boot/vendor-clk.txt
grep -iE 'monitor|pcie' /boot/vendor-clk.txt
```

This is worth more than the raw registers: what bit us was a *reference count*
(nothing held `pllout_monitor_clk2`, so `clk_disable_unused()` gated it), not a
wrong register value, and `clk_summary` prints `enable_cnt`/`prepare_cnt` per
clock.

The three anatop fields directly, to compare against what we set. Mendel is
Debian and has no busybox, so use python rather than `devmem`; `mmap` with
`O_SYNC` is also more reliable than `dd` on `/dev/mem` for MMIO on arm64:

```sh
python3 - <<'PY'
import mmap, os, struct
base = 0x30360000
fd = os.open("/dev/mem", os.O_RDONLY | os.O_SYNC)
m = mmap.mmap(fd, 0x1000, mmap.MAP_SHARED, mmap.PROT_READ, offset=base)
for off in (0x74, 0x7c):
    print(f"{base+off:#010x} = {struct.unpack('<I', m[off:off+4])[0]:#010x}")
PY
```

`0x…74` low nibble is the mux (`0xb` = `sys_pll1_out_monitor`), bit 4 the gate;
`0x…7c` bits 2:0 the divider (`7` = /8, 800 → 100 MHz). `apt install busybox` if
`/dev/mem` turns out to be blocked.

**3. Audio runtime state.** Settles the SAI1/SAI2/SAI4 question and shows what
the codec actually exposes, which is what the missing `widgets`/`routing` in
`0017` need.

```sh
aplay -l; arecord -l; cat /proc/asound/cards
amixer -c0 scontrols
ls /sys/kernel/debug/asoc/; cat /sys/kernel/debug/asoc/components
```

Whether an HDMI card appears here is also worth knowing — it would say the
vendor's MHDP audio driver works and via which SAI.

**4. Bluetooth**, which we have never looked at. The QCA6174 is a combo part
with BT on a UART and nothing in our DT describes it.

```sh
hciconfig -a; ls /sys/class/bluetooth/
dmesg | grep -iE 'blue|hci|qca'
```

**5. Lower value, but cheap:** `lspci -nnvv` (link speeds and the Edge TPU),
`ls /sys/class/typec/` (the ptn5150), `cat /sys/class/thermal/thermal_zone*/type`.

### Temperature and throttling

There is one thermal zone, `cpu-thermal`, in millidegrees:

```sh
awk '{printf "%.1fC\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp
```

Watch it against the current frequency — this is the pair that matters, since
the failure mode was the cores sitting at 1.5 GHz with nothing throttling them:

```sh
while :; do
  printf '%s  %s kHz\n' \
    "$(awk '{printf "%.1fC", $1/1000}' /sys/class/thermal/thermal_zone0/temp)" \
    "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)"
  sleep 2
done
```

`CONFIG_CPU_THERMAL` working shows up as cooling devices existing at all:

```sh
for d in /sys/class/thermal/cooling_device*; do
  echo "$(cat $d/type) cur=$(cat $d/cur_state) max=$(cat $d/max_state)"
done
```

Expect a `cpufreq-*` entry and a `gpio-fan` entry. Before the fix there were
none, which is precisely why nothing throttled. The trip points the board
should be acting on are in `imx8mq-phanbell.dts`: fan on at 65 °C, passive at
75 °C and 80 °C, critical at 90 °C.

```sh
grep . /sys/class/thermal/thermal_zone0/trip_point_*_type \
       /sys/class/thermal/thermal_zone0/trip_point_*_temp
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
