# PKG_TOOLCHAIN conversion plan

Published as a comment on issue 5970: <https://github.com/LibreELEC/LibreELEC.tv/issues/5970#issuecomment-4876419657> — keep this file and that comment in sync.

Worklist for "update packages to meson/cmake build": one row per package that hardcodes `PKG_TOOLCHAIN`. The `Notes` column is yours — decisions, WIP refs, verdicts.

> **Data source: `master` @ `cb345f8142ba594027ca46f36c12f395fb288cd0`**, verified against the package.mk files.

## Method

```bash
tools/toolchain-scan
```

`tools/toolchain-scan` sources `config/options <pkg>` per package (expanding `PKG_VERSION` / `PKG_TOOLCHAIN` / `PKG_SOURCE_NAME` / `SOURCES`), lists the real archive under `$SOURCES`, and replicates the `scripts/build` auto-detector at the **root** of the source (`meson.build > CMakeLists.txt > configure > Makefile`), then compares it to the hardcoded value.

- `auto` never yields `autotools` — dropping it gives `configure` (no autoreconf), so an `autotools` line is always load-bearing.
- `cmake-make` / `ninja` are not auto-detectable — always load-bearing.
- A "convert" is a **port** of `PKG_CONFIGURE_OPTS_TARGET` / `PKG_BUILD_FLAGS` to the new backend, not a line-drop.
- Target priority is **meson > cmake > configure**. Convert toward meson wherever the source ships `meson.build`; cmake is only the target when meson isn't available. A package already on cmake that ships meson is still a meson-convert candidate.

## 1. early/correct, must not move

| package | ver | now | why pinned | Notes |
|---|---|---|---|---|
| ccache | 4.13.6 | cmake-make | built before ninja exists | |
| cmake | 4.3.4 | configure | bootstraps cmake itself | |
| libfmt | 12.1.0 | cmake-make | early dep; ninja backend avoided | |
| zlib | 1.3.2 | cmake-make | built before ninja exists | |
| zstd | 1.5.7 | cmake-make | built before ninja exists | |

`ninja` scans as `manual` (not `cmake-make`) — issue-body line for it is stale.

## 2. Drop the redundant hardcode

Verified: `auto` == hardcode, so only the redundant line goes — all `PKG_*_OPTS` / `PKG_BUILD_FLAGS` stay. Confirm with a rebuild.

| package | ver | now | auto | evidence | Notes |
|---|---|---|---|---|---|
| double-conversion | 3.4.0 | cmake | cmake | keeps `-sysroot` flag | |
| eglexternalplatform | 1.2.1 | meson | meson | | |
| grub | 2.14 | configure | configure | hardcode redundant (auto=configure); it carries a 272-line const-qualifier patch that autoreconf may make unnecessary — worth testing | |
| hyperhdr | 21.0.0.0 | cmake | cmake | | |
| libretro-swanstation | git | cmake | cmake | | |
| nvidia_egl-gbm | 1.1.3 | meson | meson | | |

## 3. Convert — source ships a modern build at root (port opts, then drop hardcode)

`tried?` marks a conversion already attempted (and reverted) — record the status / next step in Notes. Blank = not yet attempted.

| package | ver | now | → target | opts / notes | tried? | Notes |
|---|---|---|---|---|---|---|
| argtable2 | 2.13 | autotools | argtable3 | retire, don't convert | | |
| dvbsnoop | git | autotools | cmake | `-sysroot -cfg-libs` | | |
| exiv2 | 0.28.8 | cmake | meson | port cmake opts | yes (reverted ×3) | |
| flac | 1.5.0 | autotools | cmake | configure opts + `+pic -cfg-libs` | | |
| fontconfig | 2.18.1 | configure | meson | `--with-arch` …; mind -O3→-O2 | | |
| freetype | 2.14.3 | configure | meson | `LIBPNG_CFLAGS` … | yes (reverted) | |
| hidapi | 0.15.0 | cmake | meson | port cmake opts | | |
| json-c | 0.19 | cmake | meson | port cmake opts; blocked upstream [json-c#938](https://github.com/json-c/json-c/issues/938) | | |
| libass | 0.17.5 | configure | meson | `--disable-test` … | | |
| libconfig | 1.8.2 | autotools | cmake | `--enable-static` | yes (reverted) | |
| libdnet | 1.18.2 | autotools | cmake | `+pic` | | |
| libnfs | 6.0.2 | autotools | cmake | `--disable-examples` … | yes (reverted) | |
| libpcap | 1.10.6 | configure | cmake | port configure opts | | |
| libpng | 1.6.58 | configure | cmake | port configure opts | | |
| libsamplerate | 0.2.2 | autotools | cmake | configure opts | | |
| libunwind | 1.8.3 | autotools | cmake | static/no-shared/no-docs/no-tests + `+pic` | | |
| libvorbis | 1.3.7 | autotools | cmake | configure opts + `+pic` | | |
| libxml2 | 2.15.3 | cmake | meson | port cmake opts; LE just moved to cmake — confirm why not meson | | |
| libyaml | 0.2.5 | configure | cmake | port configure opts | | |
| nlohmann-json | 3.12.0 | cmake | meson | port cmake opts | yes (reverted) | |
| opus | 1.6.1 | configure | meson | configure opts | yes (reverted) | |
| swig | 4.4.1 | configure | cmake | port configure opts | | |
| tcpdump | 4.99.6 | configure | cmake | port configure opts | | |
| tinyxml2 | 11.0.0 | cmake | meson | port cmake opts | | |
| util-linux | 2.42.2 | autotools | meson | meson experimental + patches build files → hard | | |
| xf86-video-intel | git | autotools | meson | `--disable-backlight` … | | |
| xz | 5.8.3 | configure | cmake | port configure opts | | |

`openvpn` ships a cmake build too, but upstream marks it unsupported (README.cmake.md) — kept on configure (see §5).

## 4. autotools INVESTIGATE — could be a plain `configure`

Ship `./configure`, patch no build files → autoreconf may be unnecessary (or needed only for gettext/libtool). Decide per package: keep `autotools` or drop to `configure`.

| package | ver | Notes |
|---|---|---|
| alsa-lib | 1.2.16.1 | |
| alsa-utils | 1.2.16 | |
| autossh | 1.4g | |
| boblightd | 478 | |
| exfatprogs | 1.4.2 | |
| file | 5.48 | |
| gpgme | 2.1.2 | |
| iperf | 3.21 | |
| iptables | 1.8.13 | master: autotools, **no patches**, ships ./configure → strong configure candidate |
| iwd | 3.12 | |
| libassuan | 3.0.2 | |
| libdaemon | 0.14 | |
| libimobiledevice | 1.4.0 | |
| libimobiledevice-glue | 1.3.2 | |
| libplist | 2.7.0 | |
| libraw | 0.22.1 | |
| libstatgrab | 0.92.1 | |
| libtatsu | 1.0.5 | |
| libtool | 2.5.4 | master: autotools, 1 patch (host-libs, not a build file) |
| libusb-compat | 0.1.9 | |
| libusbmuxd | 2.1.1 | |
| libxshmfence | 1.3.3 | |
| mtools | 4.0.49 | |
| mtpfs | git | |
| net-snmp | 5.9.5.2 | |
| nettle | 4.0 | |
| newt | 0.52.25 | |
| ntfs-3g_ntfsprogs | 2022.10.3 | |
| open-vm-tools | 13.1.0 | |
| patchelf | 0.19.0 | |
| screen | 5.0.1 | |
| speech-dispatcher | 0.12.1 | |
| w_scan2 | 1.0.17 | |
| xf86-input-evdev | 2.11.0 | |
| xf86-input-libinput | 1.5.0 | |
| xf86-input-synaptics | 1.10.0 | |
| xf86-video-amdgpu | 23.0.0 | master: autotools, ships ./configure |
| xf86-video-vmware | 13.4.0 | |

## 5. Keep — load-bearing, no action

### autotools: ships no ./configure (git snapshot, must autoreconf)

| package | ver | Notes |
|---|---|---|
| bwm-ng | 0.6.3 | |
| cifs-utils | 7.6 | |
| comskip | 0.83 | |
| connman | 2.0 | |
| dotconf | 1.4.1 | |
| eventlircd | git | |
| evtest | 1.36 | |
| fuse | git | |
| hddtemp | 0.4.4 | |
| heimdal | git | |
| htop | 3.5.1 | |
| iftop | git | |
| inadyn | 2.13.0 | |
| inotify-tools | 4.25.9.0 | |
| krb5 | 1.22.2 | |
| lcdd | git | |
| libcap-ng | 0.9.3 | |
| libconfuse | 3.3 | |
| libdvbcsa | git | |
| libestr | 0.1.11 | |
| libhid | git | |
| liblognorm | 2.1.0 | |
| libshairplay | git | |
| libugpio | 0.0.7 | |
| mumudvb | git | |
| nqptp | 1.2.8 | |
| nss-mdns | 0.15.1 | |
| ntfsprogs-plus | git | |
| procps-ng | 4.0.6 | |
| rar2fs | 1.29.7 | |
| shairport-sync | 5.0.4 | |
| speex | 1.2.1 | |
| speexdsp | 1.2.1 | |
| tinyxml | 2.6.2 | |
| tntnet | git | |
| usbmuxd | git | |
| xmlstarlet | 1.6.8 | |
| zvbi | 0.2.44 | |

### autotools: patches build files (autoreconf required)

| package | ver | Notes |
|---|---|---|
| bluez | 5.86 | |
| elfutils | 0.195 | |
| flex | 2.6.4 | |
| fluxbox | 1.3.7 | |
| itstool | 2.0.7 | |
| libaacs | 0.11.1 | |
| libffi | 3.6.0 | |
| libgcrypt | 1.12.2 | |
| libirman | 0.5.2 | |
| libmtp | 1.1.23 | |
| libX11 | 1.8.13 | |
| lirc | 0.10.2 | |
| minidlna | 1.3.3 | |
| nftables | 1.1.6 | |
| openssh | 10.3p1 | |
| Python3 | 3.14.6 | |
| strace | 7.1 | |
| udisks | 2.10.1 | |
| xorg-launch-helper | 4 | |

### configure: no root build file / special

| package | ver | why | Notes |
|---|---|---|---|
| avahi | 0.8 | configure generated | |
| icu | 78.3 | configure not at root | |
| openssl | 3.6.3 | perl `Configure` | |
| openvpn | 2.7.5 | cmake unsupported upstream ([README.cmake.md](https://github.com/OpenVPN/openvpn/blob/master/README.cmake.md)) — stays configure | |
| qemu | 11.0.2 | configure wraps meson | |

### cmake: script in a subdir (auto can't detect)

Hardcode structurally required — `auto` finds no root build file.

| package | ver | note | Notes |
|---|---|---|---|
| llvm | 22.1.8 | CMakeLists in `llvm/` subdir | |

## Not classified

`manual` / `python` / `python-flit` toolchains (custom install or Python build systems) are out of scope for the meson/cmake conversion.
