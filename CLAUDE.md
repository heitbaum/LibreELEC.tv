# LibreELEC.tv — Claude Code guidance

## Project

LibreELEC is a minimal "Just Enough OS" Linux distribution built exclusively to run Kodi. It is a fork of OpenELEC. GPL-2.0.

# Coding Standards
@STANDARDS.md

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

@COMPILER-WORKAROUNDS.md

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

### Amlogic project patch renaming

~97 patch files under `projects/Amlogic/` still use the `amlogic-NNNN-` prefix and need renaming to `####-subject.patch` to match the standard convention. Same work as already done for Allwinner, NXP, Samsung, Dragonboard, and Rockchip on branch `m3`.

Directories to rename:
- `projects/Amlogic/devices/AMLGX/patches/linux/` — ~90 patches
- `projects/Amlogic/devices/AMLGX/patches/u-boot/` — 6 patches
- `projects/Amlogic/patches/alsa-lib/` — 1 patch

Also check whether these patches need `git format-patch` headers added (same follow-up done for NXP/Dragonboard/Allwinner). Use `rename_plan.py` to generate the rename plan.

### Patches missing `---` separator

~110 patch files under `packages/` lack the blank `---` separator line between the commit message body and the diff stat block. They apply correctly but don't conform to git format-patch output. Excludes packages with `PKG_NO_REFRESH_PATCHES` set (ffmpeg, moby, podman-bin) — those patches are script-generated and must not be manually edited.

@PATCHES.md

## Current Toolchain Versions

- GCC: 16.1.0
- OS version: 13.0 (devel)
- Addon version: 12.80.7

## Commit discipline

- One concern per commit — never bundle unrelated changes
- New `package.mk` files use `GPL-2.0-only` licence, not `GPL-2.0-or-later`
- Use "and" not ";" to join clauses in commit messages

## What Next for LE13 — Ideas / Roadmap

### Open Issues / PRs — triage (reviewed 2026-06-22)

Many open issues map onto **Improvements** items below and are cross-referenced inline there:
#7602 (rpath), #5970 (meson/cmake group), #5952 (pkgconf `Libs.private`), #5535 (python cross-compile), #8273 (libxkbcommon compose-data), #10189 (rust target), #11242 (gold linker → Retire/Replace, LE14), #9893 (CONFIG_COMPAT, split up), PR #5162 (binary toolchain → sccache).

Action-classified (ready to pick up later — do each as its own commit/PR):

| # | Verdict | Action |
|---|---|---|
| [#5486](https://github.com/LibreELEC/LibreELEC.tv/issues/5486) llvm ignores C/CXX flags | **already resolved** | cmake is now 4.3.4 (bug was cmake ≥3.20); the offending `C_FLAGS`/`CXX_FLAGS` lines are gone from `packages/lang/llvm/package.mk`. → **close as resolved**. |
| [#9917](https://github.com/LibreELEC/LibreELEC.tv/issues/9917) create_addon mishandles incompatible addons | **MERGED upstream** | The `optional`-mode `get_addons` fix is on `upstream/master` (`scripts/create_addon`, byte-identical to our local work). Background: the drop handler crashed because `get_addons` calls `die` on zero compatible matches; dropping an arch-incompatible addon (`-argononecontrol` on x86_64) killed the build. NB the naive `addons_drop+=" ${1:1}"` is **wrong** (tested: raw filter silently breaks group/regex drops so `all -binary` builds everything); the merged fix keeps expansion and adds the `optional` flag. Test harness: `scripts/tests/create_addon-drop`. Our local dev commit is now redundant. |
| [#10746](https://github.com/LibreELEC/LibreELEC.tv/issues/10746) snapclient: Host ID with whitespace fails | **FIXED upstream before us** | Resolved by `413af9a1c6` (s7a7ic, "whitespace support in Host ID"), building on dallmair PR #11221 (`b977441f62`). Upstream wraps the args in `/bin/sh -c "snapclient $ARGS"`, so the inner shell re-parses and honours the `'$sc_h'` quotes (the original bug was the *unquoted* `snapclient $sc_H` form word-splitting `'libre elec'`). Our `set -- … "$@"` + `exec` variant is redundant — though slightly more robust (also survives a single-quote *inside* the Host ID, e.g. `it's`, which the `sh -c` form still breaks). Our local dev commit is redundant. |
| [#10752](https://github.com/LibreELEC/LibreELEC.tv/issues/10752) snapclient breaks ALSA output / passthrough | **hard — investigate** | snapclient depends on `alsa-plugins snapcast` (no direct pulseaudio) but copies alsa plugin `.so`s into the addon and sets `ALSA_PLUGIN_DIR` at them; that makes Kodi enumerate "PULSE: Default" and lose passthrough. Needs real investigation (which plugin, Kodi audio detection); reporter links a "better long-term solution" kodi thread. Related to #10746. |
| [#10532](https://github.com/LibreELEC/LibreELEC.tv/issues/10532) clean up harmless boot-log errors | **mostly done** | `Unknown group 'clock'` fixed by `b0cb0c8d56` (`add_group clock 107` in `packages/sysutils/systemd/package.mk`). `90-alsa-restore.rules NAME="snd/%k"` already removed from `packages/audio/alsa-utils/udev.d/90-alsa-restore.rules` (check the `rpi-cirrus-config` copy too). Remaining: pulseaudio cookie + bluez5 `GetManagedObjects` noise — benign, fiddly, tied to the same pulse situation as #10752. Verify on a current build then tick off the udev items. |

Not interested (do not track): #6426 (split debug symbols), #5219 (kernel HID options), #9341 (sources mirror tools), #8279 (download-cleaner), #9395 (junk → close).

Progressing, not tracked here: PR #11104 (OpenSSL 4.0.x), PR #11494 (libfmt 12.2.0 — un-draft using dev commits `5f3a638708`/`e9ba65744d`/`c923828061`).

### GitHub issue templates & automation

- **Bug report form** — converted the legacy markdown template to a GitHub **Issue Form**: drafted at `.github/ISSUE_TEMPLATE/bug-report.yml` (working tree on `dev`, **uncommitted**); legacy `.github/ISSUE_TEMPLATE/bug-report.md` removed. Required fields (block submission): prerequisites checkboxes, exact version, release channel, platform dropdown (Generic/RPi5/RPi4/RPi2-3/Allwinner/Amlogic/Rockchip/NXP/Qualcomm/Samsung/RISC-V/Other), description, repro steps, **debug log URL**, **forum thread URL**. Fixes the `https//` typo; keeps `config.yml` (`blank_issues_enabled: false` + forum/feature-request contact links). YAML lints clean. **To action:** review + commit, open as upstream PR.
- **Issue automation (deferred — form first, then decide).** Candidate GitHub Actions workflows (would live in `.github/workflows/`, need `issues: write`):
  - **Stale bot** (`actions/stale`) — label `stale` then close after N days inactivity; target `ISSUE NEEDS REVIEW` / needs-info. Handles the "usual" cleanup.
  - **EOL / not-current** — on open, read the version field; if end-of-life, comment + label `not-current` (optionally close).
  - **Missing-info enforcement** — on open, verify debug-log + forum URLs present/valid; if not, comment + label `needs-info` (belt-and-braces over the required form fields).
  - **New-issue triage comment** — auto-comment the triage checklist + forum-first reminder, apply default labels.

### Improvements

- braces (`${FOO}` not `$FOO`, per STANDARDS.md). Status by tree:
  - `packages/` — done
  - `distributions/` — near-done; 4 trivial left (2× `$DISTRO_VERSION` in URLs, 2× `$PROJECT` in `${DEVICE:-$PROJECT}`)
  - `scripts/` — near-done; ~11 left in `check_kernel_config`, `image`, `mkimage`, `pkgbuild`
  - `tools/` — ~199 left; worst: `repo-tool` (59), `mkpkg/mkpkg_pvr` (20), `icon-generate` (18), `distro-tool` (12)
  - `config/` — ~435 left; `config/functions` (329) is the big one (sourced by every package hook)
  - `projects/` — known issue; many unbraced
  - STANDARDS.md — audit the examples themselves
  - (counts are pre-filter; single-quoted strings / awk `$NF` inflate slightly)
- **xmlstarlet** — upstream is dead (SourceForge 1.6.1, 2014) and no maintained *source* fork exists (only distro patch sets — Fedora/Debian/etc.). We currently pull from the **archived** `dimitern/xmlstarlet` *python-bindings* repo (tagged `v1.6.8`; `PKG_SITE` wrongly points at pypi) and carry accumulating libxml2-compat patches (2.12.0 / 2.14.0 / xmlError-const). Options: (a) fix provenance — canonical source + distro-tracked patches; (b) stand up a `LibreELEC/xmlstarlet` fork to consolidate; (c) replace — **blocked**: `config/functions` and `scripts/install_addon` use `xml ed --inplace` / `esc`, not just xpath, so `xmllint` can't substitute. NB the `xmlstarlet-0247-xmlErrorPtr…` patch is missing from PATCHES.md (tracking gap to fix).
- **meson: cross-compiled python correctness** — cross-compiled Python3 bakes in build-host CFLAGS that break the cross-compiler (https://github.com/LibreELEC/LibreELEC.tv/issues/5535, still open — see also the recent libgpiod issue). NB the sibling bug, cross-compiled meson not using the cross-compiled libraries / failing meson.build tests (#5536), is **closed/fixed** (2026-07-02; regression guard added under `scripts/tests`).
- **update-pkg** — normalise the tool; remove boilerplate/duplication.
- **update-scan** — output is noisy because comparison is plain string inequality (`PKG_VERSION != upstream_version`), with no normalisation or semantic compare. Of ~85 reported lines, ~30 are noise:
  - cosmetic-equal false positives (packaging/prefix/snapshot suffixes): boost `1.91.0` vs `1.91.0-1`, libsodium `-RELEASE`, libfyaml `v` prefix, flatbuffers date+hash tail, pycparser `3.0` vs `3.00`, opencaster `+dfsg`, ncurses `-20260620`.
  - downgrades reported as updates (upstream older): memtester `4.7.1→4.5.1`, libtool `2.6.0→2.5.4`, proftpd `rc2→rc1`, firmware-imx `8.31-hash→8.31`.
  - pre-release noise (no filter): jellyfin rc1, qt5 beta1, lxml a3, encfs beta1, nqptp -dev, tmux -rc, nvme-cli -a.5, hyperhdr beta2, groovy ALPHA_1.
  - divergent numbering: protobuf `21.12→35.1`, qt5→qt6, x264 hash→`3222`.
  - bugs: mesa-reusable prints literal `${OS_VERSION}-${MESA_VERSION}` (PKG_VERSION never expanded — skip pkgs whose version still contains `${`); git-hash TAG column takes unsorted `.[0]` from `/tags` so shows ancient junk (heimdal 2011, fuse 2001, usbmuxd 2012) — sort tags by date/`-V`.
  - Fix plan (priority): (1) normalise (strip leading `v`, packaging/snapshot suffixes) + `sort -V` and only report when upstream is strictly greater; (2) pre-release filter with `PRERELEASE=yes` opt-out; (3) skip unexpanded `${`/self-hosted versions; (4) fix git tag selection; (5) per-package scheme overrides (protobuf/qt5/x264) like the existing nvidia special-case. Fix #1 removes the bulk.
- **nqptp** — complete it. Current WIP is "average"; redo as a focused, proper job.
- **lldpd** — ship as an addon (preferred over baking into the base image + distribution file).
- **consistently set CONFIG_SECURITY** — review and tackle as a cleanup across all `.conf` kernel config files.
- meson-build upstreaming group (all WIP, all need fixing/landing upstream — local attempts reverted). Part of the broader "update packages to meson/cmake build" cleanup (https://github.com/LibreELEC/LibreELEC.tv/issues/5970) — reaudit which packages still use autotools; this group is the set of conversions I've attempted and failed so far:
  - **nlohmann-json: with meson** — get upstreamed; there is related work in a PR at upstream.
  - **exiv2: meson** — same; fix upstream.
  - **opus: meson** — same.
  - **libconfig: build with cmake not autotools** — same; current attempt doesn't work.
  - **freetype: build to meson** — same; current attempt doesn't work.
- **kernel firmware compress** — a task (to be done).
- **rtmpdump** — find a better upstream.
- **libaacs** — find/confirm a maintained upstream to track (current source uncertain).
- **mesa: enable zstd compression for mesa shader** — zstd is already in the OS: `zstd:target` builds a shared `libzstd.so` (`BUILD_SHARED_LIBS=ON`, `ZSTD_BUILD_STATIC=OFF`), and mesa already pulls it in transitively (mesa → `libarchive` → `zstd`, see `packages/graphics/mesa/package.mk` `PKG_DEPENDS_TARGET+=" libarchive …"`). mesa also already has `-Dshader-cache=enabled` but does not yet use zstd for it. So enabling adds **no new library** — just add an explicit `zstd` to mesa `PKG_DEPENDS_TARGET` and `-Dzstd=enabled` to `PKG_MESON_OPTS_TARGET` (what reverted WIP `0faf137092` did). Low-risk to redo properly.
- **linux: mac80211: spectmgmt: improve log error** — write the patch properly for upstream kernel submission.
- **mkimage: use ENV to skip creation of virtual appliance** — discussed before in a LE:master PR; just do it properly.
- **riscv** — merge the LE `tools/` commits upstream, but do NOT deploy a device build.
- **mp4v2** — move to the current 2.x version and add to `multimedia-tools`.
- **allwinner** — not ready; investigate what's needed to get a test build up on Radxa A5E.
- **libxkbcommon: add compose-data dependency** (https://github.com/LibreELEC/LibreELEC.tv/issues/8273) — missing dependency; HELP WANTED.
- **rust: build targets don't match TARGET** (https://github.com/LibreELEC/LibreELEC.tv/issues/10189) — rust build target triple mismatch.
- **hid_mapper** — submit the cross-compile Makefile fix (`0001`, hardcoded `g++`/`gcc` → `${CXX}`/`${CC}`) upstream to s-leroux/hid_mapper. `0002` is dspinellis PR #4 and `0003`'s includes are covered by PR #3; upstream dormant since 2014 so unlikely to merge — bookkeeping.
- **nmap: submit autotools patch** — the automake-1.17 build patch (`0001-allow-build-with-automake-1-17`) has no upstream PR; submit to nmap upstream (nmap-dev) or confirm its status.
- **avahi 0.9-rc5** — WIP bump on dev (master is 0.8): drops the dbus-path backport and carries `229.patch` (upstream PR #229, open, v0.9.1 milestone) and `309.patch` (upstream PR #309, closed unmerged) for the 0.9 branch. Land/reconcile when 0.9 stabilises, and rename `229.patch`/`309.patch` to the `####-subject.patch` convention.
- **linux: aarch64: drop CONFIG_COMPAT** (https://github.com/LibreELEC/LibreELEC.tv/pull/9893) — my PR; probably split it up (per-platform) to land incrementally.
- **rpath** (lib.private via RPATH, https://github.com/LibreELEC/LibreELEC.tv/issues/7602) — main image validated clean; `tools/check-rpath` added to scan for regressions; addons still have issues. Remaining blockers: deal with **sundtek** (sundtek-mediatv) and the **JRE** addon. Note: **lbin is a separate concern** (binary placement, not RPATH) — see the lbin item below.
- **schedutil power governor** — switch `CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL=y` on all platforms. Done: Generic x86_64, Allwinner aarch64, Rockchip aarch64. Still `ondemand`: Amlogic aarch64, NXP iMX6/iMX8, Qualcomm Dragonboard, Rockchip RK3288/RK3328/RK3399, RPi/RPi2/RPi4/RPi5, Samsung. Still `performance`: Allwinner A20 (arm), Allwinner arm.
- **lbin addon files** (distinct from the rpath/#7602 work above — this is about binary *placement*, not RPATH) — addon binaries that only serve the addon itself should live in `lbin/` inside the addon directory, not in system paths like `/usr/bin`. Mirrors the `lib.private/` pattern already used for addon-private libraries (keeps `LD_LIBRARY_PATH` clean). `nextpvr` is the reference example: `hdhomerun_config` and `comskip` go to `lbin/`, `libmediainfo.so` goes to `lib.private/`. Audit all addons that install to `/usr/bin` or `/usr/sbin` and move addon-only binaries to `lbin/`.
- **sccache** — use for caching build-host compilation; analogous to mesa-reusable (pre-built mesa host tools) but for the full toolchain / host packages. Prior WIP: PR https://github.com/LibreELEC/LibreELEC.tv/pull/5162 (`tools/generate-toolchain` script — packages a versioned aarch64 GCC toolchain as a tarball with SHA256 for distribution). Also: a hacky dev-branch experiment tarring up a built toolchain and validating via hash. End goal: `USE_REUSABLE_TOOLCHAIN=yes` style flag that downloads a pre-built toolchain tarball (same model as mesa-reusable) instead of compiling it from source — needs proper fallback/check logic (mesa-reusable approach needs improvement in this area too).

### Obsolescence

- **syslinux** — dead/unmaintained; replacing with systemd-boot for LE13 (UEFI-only agreed). systemd already builds `systemd-boot.efi` for Generic (`-Dbootloader=enabled`, commit `3c8c56c8`); not yet wired into `scripts/mkimage`. See `syslinux-replacement.md` for full investigation notes.
- **udevil** — goal is a minimal device-mount system without bloatware (udisks3 is too heavy). Migrated from dead original (ignorantguru) to maintained fork `arnie97/udevil-ng` (https://github.com/arnie97/udevil-ng); currently pinned to git hash `666e443c`. End state TBD: evaluate whether udevil-ng is the right long-term minimal solution, or whether a lighter custom approach exists.
- **pkg-config → pkgconf** — migrate `packages/devel/pkg-config` (0.29.2, last release 2017) to pkgconf (https://github.com/pkgconf/pkgconf/, latest 2.5.1 June 2025). pkgconf is a drop-in replacement but NOT bug-compatible — stricter standards compliance. Known issue: pkgconf (and pkg-config) does not honour `Libs.private` for static linking in cross-compile builds — packages use workaround hacks (see https://github.com/LibreELEC/LibreELEC.tv/issues/5952; partial fixes in mpd PR#9628 and elfutils PR#9621). Migration must also resolve the `Libs.private` static-linking problem. Migration notes: (1) autotools build; (2) add symlink `pkg-config → pkgconf` in `post_makeinstall_host`; (3) set `--with-system-libdir`, `--with-system-includedir`, `--with-pkg-config-dir` for cross-compile paths; (4) strict `.pc` validation may expose masked issues in third-party packages — document first, then attempt build-wide.

### Retire / Replace

- **Docker iptables → nftables** — move Docker to native nft (still experimental; target LE14+)
- **iptables** — drop completely once nft transition is complete
- **gold linker** — retire gold linker support (https://github.com/LibreELEC/LibreELEC.tv/issues/11242); LE14 work.

### Platforms

- **Allwinner H700/H618 (sun50iw9/sun50iw10) — A523 SoC** — add support
- **Qualcomm** — fix broken platform support
