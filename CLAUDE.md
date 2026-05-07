# LibreELEC.tv — Claude Code guidance

## Project

LibreELEC is a minimal "Just Enough OS" Linux distribution built exclusively to run Kodi. It is a fork of OpenELEC. GPL-2.0.

## Branch Model

- `dev` — Rudi's development branch. Contains patches waiting to go upstream, WIP patches, and experiments. Commits near `HEAD` are WIP/getting ready; commits near the merge base with `master` are PRs already submitted/waiting for review.
- `master` / `origin/master` — tracks upstream LibreELEC (`https://github.com/LibreELEC/LibreELEC.tv`).

When comparing or reviewing changes, diff against `master`.

## Build System

GNU Make + Bash cross-compilation. Packages are built in dependency order via `scripts/genbuildplan.py`.

```bash
# Configure and build a full image (example: Generic x86_64)
PROJECT=Generic ARCH=x86_64 make image

# Build a single package
PROJECT=Generic ARCH=x86_64 scripts/build <package-name>

# Parallel build
PROJECT=Generic ARCH=x86_64 scripts/build_mt <package-name>
```

Config loading order: `config/arch.*` → `distributions/*/options` → `projects/*/options` → `projects/*/devices/*/options`. Each level overrides the previous.

## Package System

Every package lives under `packages/<category>/<name>/package.mk`. Key fields:

| Variable | Purpose |
|---|---|
| `PKG_NAME`, `PKG_VERSION`, `PKG_SHA256` | Identity |
| `PKG_URL` | Source tarball/git URL |
| `PKG_DEPENDS_TARGET` / `PKG_DEPENDS_HOST` | Dependency graph |
| `PKG_TOOLCHAIN` | Build system: `cmake`, `autotools`, `meson`, `make`, `manual` |
| `PKG_CMAKE_OPTS_TARGET` / `PKG_CONFIGURE_OPTS_TARGET` / `PKG_MESON_OPTS_TARGET` | Build flags |
| `PKG_BUILD_FLAGS` | LibreELEC-specific flags (e.g., `+pic`, `-gold`, `-sysroot`, `-parallel`) |
| `PKG_ARCH` | Restrict to specific architectures |

Hook functions run at named build stages: `pre_configure_host()`, `pre_configure_target()`, `post_makeinstall_target()`, etc.

Patches go in `packages/<category>/<name>/patches/`.

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

## Platforms

| Project | Architecture | Notes |
|---|---|---|
| Generic | x86_64 | syslinux bootloader |
| RPi | aarch64/arm | Raspberry Pi family |
| Amlogic | aarch64/arm | Amlogic SoC boxes |
| Rockchip | aarch64/arm | RK3288/3328/3399 |
| Allwinner | aarch64/arm | H6/H616 SoCs |
| NXP | aarch64/arm | i.MX family |
| Qualcomm | aarch64 | Snapdragon |
| RiscV | riscv64 | RISC-V |

## Key Files

| Path | Purpose |
|---|---|
| `distributions/LibreELEC/version` | Version strings (`DISTRO_VERSION`, `OS_VERSION`, `ADDON_VERSION`) |
| `packages/lang/gcc/package.mk` | GCC version used for the toolchain |
| `config/options` | Global build defaults |
| `config/functions` | Core bash utilities used by all package hooks |
| `scripts/genbuildplan.py` | Build dependency resolver |
| `tools/update-functions` | Per-package helper scripts sourced by `tools/update-pkg` |
| `tools/update-pkg` | Update a package version, fetch new tarball, auto-commit |
| `tools/update-scan` | Check packages for new upstream versions |
| `tools/validate-licenses.py` | Validates `PKG_LICENSE` fields against source tarballs |

Run `tools/update-pkg PKG_NAME [PKG_VERSION]` from the repo root. After committing the version bump it unpacks the new source tarball and applies every patch from `packages/<name>/patches/` (and arch-specific subdirs), reporting failures (FAIL) and fuzz/offset issues (WARN) to stderr without aborting.

## PKG_LICENSE / SPDX Compliance

`PKG_LICENSE` must be a valid [SPDX expression](https://spdx.org/licenses/). Bare forms like `GPL-2.0` or `LGPL-2.1` are deprecated — always use the `-only` or `-or-later` suffix.

| Licence | SPDX identifier |
|---|---|
| GPL v2 only | `GPL-2.0-only` |
| GPL v2 or later | `GPL-2.0-or-later` |
| LGPL v2.1 or later | `LGPL-2.1-or-later` |
| MIT | `MIT` |
| BSD 2-clause | `BSD-2-Clause` |
| Apache 2.0 | `Apache-2.0` |

Compound expressions use ` AND ` / ` OR `: e.g. `GPL-2.0-or-later AND LGPL-2.1-or-later`.

Every identifier used in `PKG_LICENSE` — standard SPDX or `LicenseRef-` — must have a corresponding text file in `licenses/`:

```
PKG_LICENSE="MIT"                 → licenses/MIT.txt
PKG_LICENSE="GPL-2.0-only"        → licenses/GPL-2.0-only.txt
PKG_LICENSE="LicenseRef-Nmap"     → licenses/LicenseRef-Nmap.txt
```

When adding a package that requires an identifier not yet present in `licenses/`, include the text file in the same commit.

### Non-SPDX licences — `LicenseRef-`

Licences not in the SPDX list use the `LicenseRef-` prefix and follow the same `licenses/` rule above.

### File header vs PKG_LICENSE

The `# SPDX-License-Identifier:` line at the top of a `package.mk` is the licence of the **build recipe file itself**, not the upstream package. New files use `GPL-2.0-only`.

### Validation

```bash
tools/validate-licenses.py [-o output.csv] [-v] [package]
```

`-v` prints a full per-package table (label / name / status); `-vv` adds the evidence column.  A positional package name restricts the run to a single package.

## GHA Automation

CI/CD lives in the separate `LibreELEC/actions` repository. Two workflows drive automated package updates:

### Package auto-update loop (`update-package.yml`)

Triggered manually (`workflow_dispatch`). The job flow is:

1. Check out `LibreELEC.tv` and the `actions` repo on an ephemeral ubuntu-24.04 runner.
2. Run `AUTO_UPDATE=yes tools/update-scan <packages>` where `<packages>` is the contents of `actions/packages_for_autoupdate.txt`. The script queries **release-monitoring.org (Anitya)** for most packages; uses the **GitHub API** for git-hash packages (compares against latest commit + tag on the default branch) and for special cases (tvheadend43 → GitHub master HEAD; aspnet\*-runtime → dotnet/runtime releases; jellyfin → `PKG_VERSION_NUMBER`). When `AUTO_UPDATE=yes` it emits only lines where the upstream version differs: `PKG_NAME CURRENT_VERSION NEW_VERSION`.
3. Parse output into a job matrix of `{name, version}` pairs.
4. Fan out: for each pair, run the `package_version_bump_and_pr_changes` composite action, which:
   - Authenticates via a GitHub App (bot identity).
   - Checks out `LibreELEC/LibreELEC.tv` at `BASE_BRANCH` (default: `master`).
   - Adds `LibreELEC/pr-le` as a `fork` remote.
   - Runs `GHA_AUTO=true tools/update-pkg NAME VERSION` — updates `package.mk`, downloads tarball, computes SHA256, auto-commits.
   - Pushes branch `pr-automated/<pkg>-<version>` to the `pr-le` fork (skips if branch already exists).
   - Opens a PR via GraphQL from `pr-le:<branch>` → `LibreELEC/LibreELEC.tv:BASE_BRANCH`.

**Packages in `packages_for_autoupdate.txt`:**
`chrome`, `docker-compose`, `dotnet-runtime`, `filebrowser`, `glslang`, `jellyfin`, `libheif`, `libopenmpt`, `minisatip`, `rust`, `tvheadend43`, `vulkan-tools`

### Repository update loop (`update-repo.yml`)

Same composite action, but for packages whose source is a LibreELEC-owned GitHub repository (firmware, settings, etc. — `amlogic-boot-fip`, `brcmfmac_sdio-firmware`, `dvb-firmware`, `eventlircd`, `iwlwifi-firmware`, `meson-firmware`, `misc-firmware`, `script.config.vdr`, `service.libreelec.settings`, `wlan-firmware`, `dt-overlays`). Runs `GHA_AUTO=false tools/update-pkg NAME` — no version argument; the tool fetches the latest commit hash itself and uses date-based versioning.

### `GHA_AUTO` flag in `tools/update-pkg`

| Value | Behaviour |
|---|---|
| `true` | CI mode — version supplied as argument; tool updates `package.mk`, commits, then exits. Branch management and PR creation are handled by the calling action. |
| `false` / unset | Local/repo mode — tool fetches the latest version itself; per-package `create_branch` / `push_branch` / `create_pr` hooks (if defined in `tools/update-functions/<pkg>`) push the branch and open the PR. |

### `update-scan` — local interactive use

Without `AUTO_UPDATE=yes`, `tools/update-scan [PKG_NAME …]` prints a human-readable table of packages with new upstream versions. Requires GitHub credentials in `~/.libreelec/options` for full API coverage:

```ini
github_token="your_personal_access_token"
github_user="your_github_username"
```

### `mesa-reusable`

`LibreELEC/mesa-reusable` publishes prebuilt `mesa:host` tools as GitHub Releases. Setting `USE_REUSABLE=yes` in a build makes the `mesa` package download and unpack this archive instead of compiling mesa tools from source, significantly reducing build time.

## Pending Cleanup

### nvidia

nvidia is pinned to the **580.x.x** series to support the range of GPUs in use.  The 580 branch does not support newer kernels out of the box and requires patches on each kernel update.

Patch locations:

- `packages/graphics/nvidia/patches/` — kernel module build patches
- `packages/x11/driver/xf86-video-nvidia/patches/` — Xorg driver patches

Current patch: `0001-build-with-linux-7.1.patch` (added in `37bafc21da`).  When the kernel is updated, check whether the existing patches still apply cleanly and whether new ones are needed.  The joanbm repository below has historically been a useful reference for 470xx-era forward-port patches and may provide leads for 580.x.x issues:

- https://github.com/joanbm/nvidia-470xx-linux-mainline

### Commented-out code to remove

| Package | File | Lines | What to remove |
|---|---|---|---|
| rtmpdump | `packages/multimedia/rtmpdump/package.mk:68` | 3 | Compatibility symlink hack explicitly marked "to be removed" |
| dislocker | `packages/addons/addon-depends/system-tools-depends/dislocker/package.mk:11` | 1 | `#PKG_DEPENDS_CONFIG="libmbedtls"` — not a valid variable, already in PKG_DEPENDS_TARGET |
| mp4v2 | `packages/addons/addon-depends/mp4v2/package.mk:12` | 1 | `#PKG_TOOLCHAIN="autotools"` — unused, cmake is the default |
| iwd | `packages/network/iwd/package.mk:40` | 5 | Two commented-out alternative `sed` blocks for systemd service patching |

### WIP packages with commented-out code (review when stabilised)

| Package | File | Notes |
|---|---|---|
| samba | `packages/network/samba/package.mk:17` | `#PKG_WAF_VERBOSE="-v"` inside `configure_package()` — useful debug toggle, decide whether to keep or document |
| zfs | `packages/linux-drivers/zfs/package.mk:39` | Commented-out alternative install approaches (`make install`, `depmod`, separate `fs/zfs` dir) — clean up once install strategy is settled |
| gcc-riscv64 | `packages/lang/gcc-riscv64-unknown-linux-gnu/package.mk:5` | Multiple stale `PKG_VERSION`/`PKG_URL`/`PKG_SHA256` lines (both active and commented); needs tidy once toolchain version is finalised |
| buildx | `packages/addons/addon-depends/docker/buildx/package.mk:12` | ~35 lines of commented-out Go build system — remove once current build method is confirmed stable |

### Bare `GPL-2.0` SPDX identifiers in package.mk file headers

7 `package.mk` files still use the bare `GPL-2.0` SPDX identifier in their own file header (the `# SPDX-License-Identifier:` line). Per the SPDX specification, bare `GPL-2.0` is deprecated — it should be `GPL-2.0-only` to be unambiguous.

```
packages/addons/service/librespot/package.mk
packages/graphics/spirv-headers/package.mk
packages/graphics/spirv-tools/package.mk
packages/graphics/vulkan/glslang/package.mk
packages/graphics/vulkan/vulkan-headers/package.mk
packages/graphics/vulkan/vulkan-loader/package.mk
packages/graphics/vulkan/vulkan-tools/package.mk
```

### Amlogic project patch renaming

~97 patch files under `projects/Amlogic/` still use the `amlogic-NNNN-` prefix and need renaming to `####-subject.patch` to match the standard convention. Same work as already done for Allwinner, NXP, Samsung, Dragonboard, and Rockchip on branch `m3`.

Directories to rename:
- `projects/Amlogic/devices/AMLGX/patches/linux/` — ~90 patches
- `projects/Amlogic/devices/AMLGX/patches/u-boot/` — 6 patches
- `projects/Amlogic/patches/alsa-lib/` — 1 patch

Also check whether these patches need `git format-patch` headers added (same follow-up done for NXP/Dragonboard/Allwinner). Use `rename_plan.py` to generate the rename plan.

### Patches missing `---` separator

~110 patch files under `packages/` lack the blank `---` separator line between the commit message body and the diff stat block. They apply correctly but don't conform to git format-patch output. Excludes packages with `PKG_NO_REFRESH_PATCHES` set (ffmpeg, moby, podman-bin) — those patches are script-generated and must not be manually edited.

## Current Toolchain Versions

- GCC: 16.1.0
- OS version: 13.0 (devel)
- Addon version: 12.80.7

## Patch file naming convention

All patch files under `packages/` (except `packages/mediacenter/kodi` and `packages/linux/`) must follow:

```
####-subject.patch
```

### Rules

- **Number**: exactly 4 digits, zero-padded (`0001`–`9999`); `0000` is not valid
- **Subject**: `git format-patch` style — hyphens as word separators, no underscores, max 53 characters
- **Separator**: hyphen between number and subject
- **No package name prefix** — the package name is implied by the directory

### Numbering

- Sequences start at `0001` — never `0000`
- Locally-added patches use sequential numbers from `0001` with no gaps
- Upstream PR/commit reference patches retain their original number regardless of value — numbers like `0005`, `0019`, `0039`, `0086` are all valid if they encode an upstream reference; non-sequential gaps are intentional in these cases
- No duplicate numbers within the same patches directory

### Subject

- Use hyphens, not underscores: `fix-build-with-gcc-14` not `fix_build_with_gcc_14`
- Maximum 53 characters (matches `git format-patch` default)
- Derive from the git `Subject:` header where it is more descriptive than a hand-written label
- Do not include the package name in the subject: `0001-fix-build.patch` not `0001-pkg-fix-build.patch`
- Do not include upstream tracker/mailing-list noise (`SV-12345-`, `[FFmpeg-devel]`, etc.)

### Exceptions

- `packages/mediacenter/kodi` — excluded from all treewide rename rules
- `packages/linux/` — excluded entirely; do not modify any patches under this tree
- `packages/linux/patches/rockchip/` and `packages/linux/patches/rockchip-old/` — left with their original `rockchip-NNNN-` naming
- `packages/addons/addon-depends/docker/moby/patches/` — do not modify; patches maintained separately
- `packages/addons/addon-depends/podman/` — do not modify; patches maintained separately
- `packages/multimedia/ffmpeg/patches/rpi/0001-rpi.patch` — do not modify; large downstream RPi patch (~24k lines)

### Verification

Run `rename_plan.py` (repo root) to check conformance:

```bash
python3 rename_plan.py            # dry-run: print proposed renames + warnings
python3 rename_plan.py --execute  # execute git mv commands
```

## Patch file format

Most patches use `git format-patch` structure:

```
From <hash> Mon Sep 17 00:00:00 2001
From: Author Name <email>
Date: <RFC 2822 date>
Subject: [PATCH] subject line

Optional body text.
---
 path/to/file | N +/-
 N files changed, N insertions(+), N deletions(-)

diff --git a/path/to/file b/path/to/file
--- a/path/to/file
+++ b/path/to/file
@@ ... @@
 context
-old line
+new line
-- 
2.47.1
```

### Script-generated patches (keep original diff format)

A small number of patches are **regenerated from scratch by a script** rather than maintained as git commits. These must stay in the format the script produces and must **not** be given format-patch headers:

- `packages/addons/addon-depends/docker/moby/patches/0001-user-addon-storage-location.patch` — regenerated by `tools/moby/gen-patches.sh` (bulk `sed` path substitution across all `.go` files)
- `packages/addons/addon-depends/podman/podman-bin/patches/0002-path-changes.patch` — regenerated by `tools/podman-bin/gen-patches.sh` (bulk `sed` path substitution across all `.go` files)

Run from the repo root: `bash tools/moby/gen-patches.sh` / `bash tools/podman-bin/gen-patches.sh`. Same convention as `tools/ffmpeg/gen-patches.sh`. `podman-bin/patches/0001-path-changes.patch` is a normal hand-maintained git patch (specific C and vendor Go changes) — it is **not** script-generated and must have a format-patch header.

**Do not** confuse these with other patches that happen to use `diff -N*` syntax internally. A custom hand-written patch that starts with `diff -Nur` lines is still a normal patch and should have a format-patch header. Only patches regenerated by `gen-patches.sh` should stay headerless.

### Author attribution

The `From:` line must name the **patch author**, not the LibreELEC committer who imported it:

- If the original patch file contains a raw git log block (`commit <hash>\nAuthor: ...\nDate: ...`), extract the author and date from that block, use the commit hash in the `From <hash>` line, and strip the log block from the body.
- If the original contains BLFS-style metadata (`Submitted By:`, `Date:`, `Origin:`, `Description:`), use the submitter as author, the `Date:` field for the patch date, keep a concise description as body text, and strip the boilerplate fields.
- Never use the LibreELEC committer's name/email as the patch author.

## Commit discipline

- One concern per commit — never bundle unrelated changes
- New `package.mk` files use `GPL-2.0-only` licence, not `GPL-2.0-or-later`
- Use "and" not ";" to join clauses in commit messages
