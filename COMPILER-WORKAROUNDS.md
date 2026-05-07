## Compiler Workarounds — Tracking List

These are compiler compatibility overrides that should be periodically retested and removed when no longer needed. Current toolchain: **GCC 16.1.0**.

| Package | File | Flag | Reason | Added |
|---|---|---|---|---|
| aom | `packages/multimedia/aom/package.mk:20` | `TARGET_CFLAGS+=" -Wno-implicit-function-declaration"` (arm only) | gcc-14 erroring on neon declarations ([upstream bug](https://bugs.chromium.org/p/aomedia/issues/detail?id=3576)) — **confirmed still needed in 3.13.3 / gcc-16** | 2024-05 |
| audiodecoder.timidity | `packages/mediacenter/kodi-binary-addons/audiodecoder.timidity/package.mk:22` | `CFLAGS+=" -fcommon"` | gcc-10 changed default to `-fno-common`; multiple-definition link errors without this — in upstream LibreELEC | ~2020 |
| efibootmgr | `packages/addons/addon-depends/system-tools-depends/efibootmgr/package.mk:16` | `CFLAGS+=" -fgnu89-inline -Wno-pointer-sign"` | old C code requires GNU89 inline semantics; pointer sign mismatch in EFI headers — in upstream LibreELEC; likely permanent | ~2016 |
| efivar | `packages/addons/addon-depends/system-tools-depends/depends/efivar/package.mk:25` | `sed 's/-Werror//' src/include/gcc.specs` | upstream code has warnings that fail with `-Werror`; patched at configure time — in upstream LibreELEC | ~2018 |
| flatbuffers | `packages/devel/flatbuffers/package.mk:33` | `CXXFLAGS+=" -std=c++11"` | overrides global C++ standard; flatbuffers requires exactly C++11 — in upstream LibreELEC | ~2019 |
| fontconfig | `packages/x11/other/fontconfig/package.mk:25` | `sed -O3 → -O2` (CFLAGS and CXXFLAGS) | `-O3` causes correctness/stability issues in fontconfig — in upstream LibreELEC | ~2016 |
| glibc | `packages/devel/glibc/package.mk:53` | removes `-ffast-math`, `-Ofast`→`-O2`, all `-O*`→`-O2`; removes `-Wunused-but-set-variable`; adds `-Wno-unused-variable`; adds `-fno-stack-protector` | glibc is correctness-sensitive: `-ffast-math`/`-Ofast` break it; glibc implements the stack canary itself so cannot be compiled with SSP — in upstream LibreELEC; largely permanent | ~2016 |
| heimdal | `packages/devel/heimdal/package.mk:17` | `CFLAGS+=" -Wno-error=implicit-function-declaration"` (host only) | without it, configure probe for `crypt` fails → linker error `undefined reference to 'crypt'` — **confirmed still needed / gcc-16** | ~2024 |
| jasper | `packages/graphics/jasper/package.mk:22` | `CFLAGS+=" -std=gnu17"` | jasper requires GNU C17 standard — in upstream LibreELEC | ~2023 |
| libheif | `packages/graphics/libheif/package.mk:20` | `CXXFLAGS+=" -Wno-unused-variable"` | upstream code has unused variables causing -Werror failure — in upstream LibreELEC | 2021 |
| libretro-dosbox | `packages/emulation/libretro-dosbox/package.mk:21` | `CXXFLAGS+=" -std=gnu++11"` | dosbox requires GNU C++11; overrides any higher standard in global CXXFLAGS — in upstream LibreELEC | ~2020 |
| libretro-dosbox-pure | `packages/emulation/libretro-dosbox-pure/package.mk:22` | removes `-O2` and `-O3` from CFLAGS | dosbox-pure Makefile manages its own optimization; global `-O` flags conflict — in upstream LibreELEC | ~2021 |
| mariadb-connector-c | `packages/databases/mariadb-connector-c/package.mk:24` | `CFLAGS+=" -Wno-discarded-qualifiers"` | glibc-2.43 made `strchr`/`strstr` C23-compliant (const-preserving return type), mariadb assigns result to non-const — **confirmed still needed in 3.4.8 / gcc-16** | 2026-01 |
| media-driver | `packages/multimedia/media-driver/package.mk:17` | `CXXFLAGS+=" -Wno-error=array-bounds="` | gcc-15 (≥20250330) build failure — **confirmed still needed in 26.2.0 / gcc-16** | 2025-04 |
| pvr.argustv | `packages/mediacenter/kodi-binary-addons/pvr.argustv/package.mk:22` | `CXXFLAGS+=" -Wno-narrowing"` | old C++ code uses narrowing conversions, illegal in C++11 — in upstream LibreELEC; likely permanent | ~2016 |
| pvr.mediaportal.tvserver | `packages/mediacenter/kodi-binary-addons/pvr.mediaportal.tvserver/package.mk:22` | `CXXFLAGS+=" -Wno-narrowing"` | old C++ code uses narrowing conversions, illegal in C++11 — in upstream LibreELEC; likely permanent | ~2016 |
| pvr.nextpvr | `packages/mediacenter/kodi-binary-addons/pvr.nextpvr/package.mk:22` | `CXXFLAGS+=" -Wno-narrowing"` | old C++ code uses narrowing conversions, illegal in C++11 — in upstream LibreELEC; likely permanent | ~2016 |
| rsyslog | `packages/addons/service/rsyslog/package.mk:34` | `CFLAGS+=" -fcommon"` | gcc-10 changed default to `-fno-common`; multiple-definition link errors without this — in upstream LibreELEC | ~2020 |
| rtmpdump | `packages/multimedia/rtmpdump/package.mk:26` | `XCFLAGS+=" -Wno-unused-but-set-variable -Wno-unused-const-variable"` | old upstream code triggers these warnings as errors — in upstream LibreELEC | ~2021 |
| seatd | `packages/wayland/lib/seatd/package.mk:26` | `TARGET_CFLAGS+=" -Wno-unused-parameter"` | upstream treats warnings as errors; unused parameter warnings fire — in upstream LibreELEC | ~2022 |
| sidplay-libs | `packages/audio/sidplay-libs/package.mk:22` | `CXXFLAGS+=" -Wno-narrowing"` | old C++ code uses narrowing conversions, illegal in C++11 — in upstream LibreELEC; likely permanent | ~2016 |
| sqlite | `packages/databases/sqlite/package.mk:26` | `sed -Ofast → -O3`; removes `-ffast-math` | `-ffast-math`/`-Ofast` break SQLite's floating point correctness — in upstream LibreELEC | ~2018 |
| sway | `packages/wayland/compositor/sway/package.mk:26` | `TARGET_CFLAGS+=" -Wno-unused-variable"` | upstream treats warnings as errors; unused variable warnings fire — in upstream LibreELEC | ~2022 |
| swaybg | `packages/wayland/util/swaybg/package.mk:18` | `TARGET_CFLAGS+=" -Wno-maybe-uninitialized"` | upstream treats warnings as errors; maybe-uninitialized warnings fire — in upstream LibreELEC | ~2022 |
| TexturePacker | `packages/mediacenter/TexturePacker/package.mk:18` | `CXXFLAGS+=" -std=c++17"` | overrides global C++ standard; TexturePacker requires C++17 — in upstream LibreELEC | ~2020 |
| systemd | `packages/sysutils/systemd/package.mk:115` | `TARGET_CFLAGS+=" -fno-schedule-insns -fno-schedule-insns2 -Wno-format-truncation"` | `-fno-schedule-insns*`: gcc instruction reordering causes crashes on some ARM SoCs; `-Wno-format-truncation`: gcc-8 warning fires in systemd — in upstream LibreELEC | 2018 |
| udpxy | `packages/addons/addon-depends/network-tools-depends/udpxy/package.mk:23` | `CFLAGS+=" -Wno-stringop-truncation"` | gcc-8 added `-Wstringop-truncation` which fires in udpxy — in upstream LibreELEC | 2019 |
| vdr-plugin-xmltv2vdr | `packages/addons/addon-depends/vdr-plugins/vdr-plugin-xmltv2vdr/package.mk:18` | `CXXFLAGS+=" -Wno-narrowing"` | old C++ code uses narrowing conversions, illegal in C++11 — in upstream LibreELEC; likely permanent | ~2016 |
| weston | `packages/wayland/weston/package.mk:47` | `sed removes -DNDEBUG from TARGET_CFLAGS` | weston requires assertions enabled at runtime — in upstream LibreELEC | ~2020 |
| wlroots | `packages/wayland/lib/wlroots/package.mk:33` | `TARGET_CFLAGS+=" -Wno-unused-variable -Wno-unused-but-set-variable -Wno-unused-function"` | upstream treats warnings as errors; multiple unused-* warnings fire — in upstream LibreELEC | ~2022 |

To retest: remove the flag, attempt a build, check if upstream has fixed it.
