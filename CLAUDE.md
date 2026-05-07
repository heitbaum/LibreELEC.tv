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
| RPi | aarch64/arm | Raspberry Pi family (RPi, RPi2, RPi4, RPi5) |
| Amlogic | aarch64/arm | Amlogic SoC boxes (AMLG12, AMLGX) |
| Rockchip | aarch64/arm | RK3288/3328/3399/356X/3576/3588 |
| Allwinner | aarch64/arm | A20/A64/A733/H2-plus/H3/H5/H6/H616/R40 |
| NXP | aarch64/arm | i.MX family (iMX6, iMX8) |
| Qualcomm | aarch64 | Snapdragon (Dragonboard) |
| RiscV | riscv64 | RISC-V (D1) |
| Samsung | arm | Exynos |

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
| `tools/toolchain-scan` | Classifies every package that hardcodes `PKG_TOOLCHAIN` vs the auto-detector (drives `docs/toolchain-plan.md`, the #5970 meson/cmake plan) |
| `tools/patch-scan.py` | Reconciles `PATCHES.md` against the actual patch tree (stale/untracked, both directions); non-zero exit on drift so it can guard CI |

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

nvidia is pinned to the **580.x.x** series to support the range of GPUs in use (currently 580.173.02).  The 580 branch does not support newer kernels out of the box and requires patches on each kernel update.

Patch location: `packages/graphics/nvidia/patches/` — kernel module build patches.  `packages/x11/driver/xf86-video-nvidia/` carries no patches.

Current patches (dev, added in `705e31900d` for linux 7.2, replacing the reverted 7.1 pair): `drm-atomic-state-to-commit-linux-7.2.patch` and `strncpy-removed-linux-7.2.patch`.  Both still need renaming to the `####-subject.patch` convention.  When the kernel is updated, check whether the existing patches still apply cleanly and whether new ones are needed.  The joanbm repository below has historically been a useful reference for 470xx-era forward-port patches and may provide leads for 580.x.x issues:

- https://github.com/joanbm/nvidia-470xx-linux-mainline

### Commented-out code to remove — CLOSED

- **rtmpdump** — done on `master` (branch `tidy-package-comments`): removed the "to be removed" `librtmp.so.0` compatibility symlink block, and dropped a redundant duplicate `XCFLAGS` line in `make_target`.
- **dislocker / mp4v2 / iwd** — the remaining items were in `dev`-only WIP packages (dislocker, mp4v2 not upstream; iwd's commented `sed` blocks are dev-only — master's iwd is clean). Treated as WIP junk and intentionally not tracked here.

### WIP packages with commented-out code (review when stabilised)

| Package | File | Notes |
|---|---|---|
| samba | `packages/network/samba/package.mk:17` | `#PKG_WAF_VERBOSE="-v"` inside `configure_package()` — useful debug toggle, decide whether to keep or document |
| zfs | `packages/linux-drivers/zfs/package.mk:39` | Commented-out alternative install approaches (`make install`, `depmod`, separate `fs/zfs` dir) — clean up once install strategy is settled |
| gcc-riscv64 | `packages/lang/gcc-riscv64-unknown-linux-gnu/package.mk:5` | Multiple stale `PKG_VERSION`/`PKG_URL`/`PKG_SHA256` lines (both active and commented); needs tidy once toolchain version is finalised |
| buildx | `packages/addons/addon-depends/docker/buildx/package.mk:12` | ~35 lines of commented-out Go build system — remove once current build method is confirmed stable |

### Amlogic project patch renaming

92 patch files under `projects/Amlogic/` still use the `amlogic-NNNN-` prefix and need renaming to `####-subject.patch` to match the standard convention. Same work as already done for Allwinner, NXP, Samsung, Dragonboard, and Rockchip on branch `m3`.

Directories to rename:
- `projects/Amlogic/devices/AMLGX/patches/linux/` — 85 patches
- `projects/Amlogic/devices/AMLGX/patches/u-boot/` — 6 patches
- `projects/Amlogic/patches/alsa-lib/` — 1 patch

Also check whether these patches need `git format-patch` headers added (same follow-up done for NXP/Dragonboard/Allwinner). Use `rename_plan.py` to generate the rename plan.

### Patches missing `---` separator

95 patch files under `packages/` lack the blank `---` separator line between the commit message body and the diff stat block. They apply correctly but don't conform to git format-patch output. Excludes packages with `PKG_NO_REFRESH_PATCHES` set (ffmpeg, moby, podman-bin) — those patches are script-generated and must not be manually edited.

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
#7602 (rpath), #5970 (meson/cmake group — audit done, see `docs/toolchain-plan.md` + `tools/toolchain-scan`), #5952 (pkgconf `Libs.private`), #5535 (python cross-compile), #10189 (rust cross via meson — experimental upstream), #11242 (gold linker → Retire/Replace, LE14), #9893 (CONFIG_COMPAT, split up), PR #5162 (binary toolchain → sccache).

Action-classified (ready to pick up later — do each as its own commit/PR):

| # | Verdict | Action |
|---|---|---|
| [#5486](https://github.com/LibreELEC/LibreELEC.tv/issues/5486) llvm ignores C/CXX flags | **already resolved** | cmake is now 4.4.1 (bug was cmake ≥3.20); the offending `C_FLAGS`/`CXX_FLAGS` lines are gone from `packages/lang/llvm/package.mk`. → **close as resolved**. |
| [#9917](https://github.com/LibreELEC/LibreELEC.tv/issues/9917) create_addon mishandles incompatible addons | **MERGED upstream** | The `optional`-mode `get_addons` fix is on `upstream/master` (`scripts/create_addon`, byte-identical to our local work). Background: the drop handler crashed because `get_addons` calls `die` on zero compatible matches; dropping an arch-incompatible addon (`-argononecontrol` on x86_64) killed the build. NB the naive `addons_drop+=" ${1:1}"` is **wrong** (tested: raw filter silently breaks group/regex drops so `all -binary` builds everything); the merged fix keeps expansion and adds the `optional` flag. Test harness: `scripts/tests/create_addon-drop`. Our local dev commit is now redundant. |
| [#10746](https://github.com/LibreELEC/LibreELEC.tv/issues/10746) snapclient: Host ID with whitespace fails | **FIXED upstream before us** | Resolved by `413af9a1c6` (s7a7ic, "whitespace support in Host ID"), building on dallmair PR #11221 (`b977441f62`). Upstream wraps the args in `/bin/sh -c "snapclient $ARGS"`, so the inner shell re-parses and honours the `'$sc_h'` quotes (the original bug was the *unquoted* `snapclient $sc_H` form word-splitting `'libre elec'`). Our `set -- … "$@"` + `exec` variant is redundant — though slightly more robust (also survives a single-quote *inside* the Host ID, e.g. `it's`, which the `sh -c` form still breaks). Our local dev commit is redundant. |
| [#10752](https://github.com/LibreELEC/LibreELEC.tv/issues/10752) snapclient breaks ALSA output / passthrough | **root-caused, not fixing now** | Diagnosed on hardware 2026-07-04 (the earlier "`ALSA_PLUGIN_DIR` makes Kodi enumerate PULSE: Default" theory is **wrong** — that var is `Environment=` in snapclient's unit, i.e. process-scoped, so it cannot affect Kodi). Real cause: `sc_s` (soundcard) defaults to empty → `snapclient.start` runs `--player alsa --soundcard default`; `aplay -L` confirms `default` = the HW card (`default:CARD=PCH`, no `/etc/asound.conf`, no `pulse` PCM), so snapclient (`Restart=always`) **seizes the hardware** and Kodi loses exclusive access for passthrough. The bundled pulse machinery is dead code: `ALSA_PLUGIN_DIR=…/lib` but plugins are in `…/lib.private` (mismatch), the `patchelf` rpath is the wrong mechanism for alsa plugin discovery, and no `pcm.pulse` definition exists anyway (alsa-plugins isn't in the base image). **Fix when picked up (keep pulse):** snapcast is built `-DBUILD_WITH_PULSE=ON`, so use the native pulse player — empty `sc_s` → `--player pulse` (coexist with Kodi), explicit `sc_s` → `--player alsa --soundcard $sc_s`; then drop `alsa-plugins` from `PKG_DEPENDS_TARGET`, the `*.so`/`lib.private`/`patchelf` in `addon()`, and the `ALSA_PLUGIN_DIR` env var; bump `PKG_REV`. **Update (upstream `df0e183ef4`, addon 3):** snapclient now finds the alsa plugin via `ALSA_PLUGIN_DIR` (pointed at the real plugin dir) instead of the patchelf rpath — resolves the rpath/`lib.private` mismatch sub-point above; the core "empty `sc_s` → `--player alsa --soundcard default` seizes the HW card" fix (switch to `--player pulse`) is still open. Separately/broader: system pulseaudio has no `module-allow-passthrough` (Kodi logs "module-allow-passthrough not loaded"). Related to #10746. |
| [#10532](https://github.com/LibreELEC/LibreELEC.tv/issues/10532) clean up harmless boot-log errors | **mostly done** | `Unknown group 'clock'` fixed by `b0cb0c8d56` (`add_group clock 107` in `packages/sysutils/systemd/package.mk`). `90-alsa-restore.rules NAME="snd/%k"` already removed from `packages/audio/alsa-utils/udev.d/90-alsa-restore.rules` (check the `rpi-cirrus-config` copy too). Remaining: pulseaudio cookie + bluez5 `GetManagedObjects` noise — benign, fiddly, tied to the same pulse situation as #10752. Verify on a current build then tick off the udev items. |

Not interested (do not track): #6426 (split debug symbols), #5219 (kernel HID options), #9341 (sources mirror tools), #8279 (download-cleaner), #9395 (junk → close).

Progressing, not tracked here: PR #11104 (OpenSSL 4.0.x — master is still on 3.6.3; **dev carries 4.0.1**, which is what surfaces the const-qualifier breakage in libwebsockets below). PR #11494 (libfmt 12.2.0) **merged** — libfmt is now 12.2.0 on master.

### GitHub issue templates & automation

- **Bug report form** — converted the legacy markdown template to a GitHub **Issue Form**: drafted at `.github/ISSUE_TEMPLATE/bug-report.yml` (working tree on `dev`, **uncommitted**); legacy `.github/ISSUE_TEMPLATE/bug-report.md` removed. Required fields (block submission): prerequisites checkboxes, exact version, release channel, platform dropdown (Generic/RPi5/RPi4/RPi2-3/Allwinner/Amlogic/Rockchip/NXP/Qualcomm/Samsung/RISC-V/Other), description, repro steps, **debug log URL**, **forum thread URL**. Fixes the `https//` typo; keeps `config.yml` (`blank_issues_enabled: false` + forum/feature-request contact links). YAML lints clean. **To action:** review + commit, open as upstream PR.
- **Issue automation (deferred — form first, then decide).** Candidate GitHub Actions workflows (would live in `.github/workflows/`, need `issues: write`):
  - **Stale bot** (`actions/stale`) — label `stale` then close after N days inactivity; target `ISSUE NEEDS REVIEW` / needs-info. Handles the "usual" cleanup.
  - **EOL / not-current** — on open, read the version field; if end-of-life, comment + label `not-current` (optionally close).
  - **Missing-info enforcement** — on open, verify debug-log + forum URLs present/valid; if not, comment + label `needs-info` (belt-and-braces over the required form fields).
  - **New-issue triage comment** — auto-comment the triage checklist + forum-first reminder, apply default labels.

### Improvements

- **libwebsockets 5.0.0 / ttyd — done, only the upstream submission is left.** master and dev both carry 5.0.0 with `-DLWS_WITH_HTTP3=OFF`, `patches/0001-tls-openssl-build-with-the-constified-X509-name-acce.patch` and ttyd bundling `libwebsockets.so.22`. Keep the two reasons on record: (a) 5.0.0 defaults `LWS_WITH_HTTP3=ON`, which force-selects **GnuTLS** as the TLS backend (`set(LWS_WITH_GNUTLS ON … FORCE)`, so `-DLWS_WITH_GNUTLS=OFF` cannot override it) — the public headers then only typedef `SSL`/`SSL_CTX`/`BIO`/`X509`, so ttyd fails on `SSL_OP_NO_TLSv1`/`X509_V_OK` while `LWS_OPENSSL_SUPPORT` still reads as set; (b) OpenSSL 4.0 constified `X509_get_subject_name()`/`X509_get_issuer_name()`, which lws's own `-Werror -Wignored-qualifiers` TLS build rejects. Both are still unfixed on lws `main` — submit the const patch to warmcat/libwebsockets.
- **offline builds — network-access audit** — stand up a framework to build packages with network access blocked *after* the source tarball/git fetch stage, so we can catch build steps that reach the network "unnecessarily" (downloading extra deps, phoning home, fetching schemas/fonts/test fixtures, `go`/`cargo`/`pip`/`npm` pulling from live registries instead of the vendored/cached copy, cmake `FetchContent`, etc.). Goal is a repeatable test that flags unexpected egress, not a hard requirement that every package be fully offline — some addons legitimately need network at build time; those become a documented allow-list. Framework ideas: run the build phase in a network namespace / firewall rule that denies egress once `unpack` completes (fetch is allowed to populate `sources/`), and report any package that fails only when offline. Fold into CI as a regression guard. First concrete piece landed upstream (PR 11585): `scripts/build` now sets meson `--wrap-mode=nodownload` for all meson builds so a missing dep fails loudly instead of silently fetching a wrap subproject (caught mpd pulling lame from wrapdb); nothing in the tree ships a `.wrap`/`subprojects/`.
- braces (`${FOO}` not `$FOO`, per STANDARDS.md). Status by tree:
  - `packages/` — done
  - `distributions/` — near-done; 4 trivial left (2× `$DISTRO_VERSION` in URLs, 2× `$PROJECT` in `${DEVICE:-$PROJECT}`)
  - `scripts/` — near-done; 17 left in `check_kernel_config` (12), `image`, `mkimage`, `pkgbuild`
  - `tools/` — 238 left; worst: `repo-tool` (87), `icon-generate` (27), `mkpkg_pvr` (27), `mkpkg_media_build` (11)
  - `config/` — 605 left; `config/functions` (448) is the big one (sourced by every package hook)
  - `projects/` — 307 left; worst: the per-project `update.sh` scripts (53/24/22) and `release` (35)
  - STANDARDS.md — audit the examples themselves
  - counts are `$VAR` occurrences in shell files only, excluding comment lines, single-quoted spans and awk field vars; `packages/` is measured over `package.mk` alone (43 left, 22 of them in the third-party `supervisedthinking/…/makemkv`) — the device-side `.start`/`init`/`installer` scripts under `packages/` are a separate, much larger body of work (~2000)
- **xmlstarlet** — upstream is dead (SourceForge 1.6.1, 2014) and no maintained *source* fork exists (only distro patch sets — Fedora/Debian/etc.). Provenance is fixed: we pull canonical 1.6.1 from SourceForge (a dev experiment on the archived `dimitern` *python-bindings* `v1.6.8` with a pypi `PKG_SITE` was reverted) and carry libxml2-compat patches `0246` (2.12) and `0900` (2.14) on both master and dev. A dev `0249`–`0252` rework of the compat layer (drop obsolete lifecycle calls, drop parser-default globals, pass entity/DTD parse flags per-call, use the xmlSave API) was tried and then dropped from the tree — dev is back to `0246`/`0900`. Options: (a) fix provenance — **done**; (b) stand up a `LibreELEC/xmlstarlet` fork to consolidate; (c) replace — **blocked**: `config/functions` and `scripts/install_addon` use `xml ed --inplace` / `esc`, not just xpath, so `xmllint` can't substitute. The carried patches are tracked in PATCHES.md. **1.6.1 will hard-break at libxml2 3.0** — it still uses libxml2's deprecated thread-global-state APIs (`xmlIndentTreeOutput`, `xmlLoadExtDtdDefaultValue`, `xmlLineNumbersDefault`, etc.), which 3.0 removes; the real trigger to replace or rework it.
- **meson: cross-compiled python correctness** — cross-compiled Python3 bakes in build-host CFLAGS that break the cross-compiler (https://github.com/LibreELEC/LibreELEC.tv/issues/5535, still open — see also the recent libgpiod issue). NB the sibling bug, cross-compiled meson not using the cross-compiled libraries / failing meson.build tests (#5536), is **closed/fixed** (2026-07-02; regression guard added under `scripts/tests`).
- **update-pkg** — normalise the tool; remove boilerplate/duplication.
- **update-scan** — output was noisy because comparison was plain string inequality (`PKG_VERSION != upstream_version`). Full classification and the per-package worklist live in `docs/update-scan-plan.md`. Generic fixes **DONE**: safe `normalise_version()` (leading `v` + zero-pad only — meaning-dependent suffixes are per-package, never global, since e.g. ncurses `6.6-YYYYMMDD` is a real snapshot); `is_prerelease()` filter (suppressed unless `PRERELEASE=yes`); `cosmetic_equal()`/`is_plain_version()`; human table shows anything that differs incl. older-upstream (stale/broken lookups worth a look) while the `AUTO_UPDATE` bot requires `upstream_strictly_newer()` so it never opens a downgrade/pre-release PR; skip unexpanded `${` versions. Remaining (per-package, need config/data not generic logic — see the doc): (A) pin-to-major-series like nvidia (qt5/mariadb/groovy/pngquant/encfs/fuse/mp4v2/protobuf); (B) track a git repo's tags/releases not Anitya (cxxtools/tntnet/dbussy/libmad/libprojectM/media-driver/x264/xf86-video-intel/…); (C) track Kodi's repo (libdvdcss/nav/read); (D) snapshot-optional base is "green" (ncurses/vim); (E) scan-ignore opt-out (rpi-eeprom/spirv-*/tigervnc/libatasmart/crazycat/…); (F) broken lookup (memtester Anitya, mesa-reusable → LE repo); (G) coupled version (heimdal↔samba, spirv↔llvm/glslang).
- **consistently set CONFIG_SECURITY** — review and tackle as a cleanup across all `.conf` kernel config files.
- **meson/cmake build conversion** — the "update packages to meson/cmake build" cleanup (https://github.com/LibreELEC/LibreELEC.tv/issues/5970). Audit is **done**: `tools/toolchain-scan` classifies every package that hardcodes `PKG_TOOLCHAIN` (it replicates the `scripts/build` root-level auto-detector and emits a verdict), and `docs/toolchain-plan.md` is the resulting worklist — sections: drop-redundant, convert, INVESTIGATE, keep; target priority **meson > cmake > configure**. The plan is posted as a comment on the issue — keep the file and that comment in sync. The meson-upstreaming subgroup below is the WIP set attempted-and-reverted (the plan's `tried?` column is authoritative — it also includes `libnfs` → cmake), all still needing to land upstream:
  - **nlohmann-json: with meson** — get upstreamed; there is related work in a PR at upstream.
  - **exiv2: meson** — same; fix upstream.
  - **opus: meson** — same.
  - **libconfig: build with cmake not autotools** — same; current attempt doesn't work.
  - **freetype: build to meson** — same; current attempt doesn't work.
- **kernel firmware compress** — a task (to be done).
- **rtmpdump** — find a better upstream.
- **libaacs** — find/confirm a maintained upstream to track (current source uncertain). Now on **0.12.0** and unpatched on both trees: the 2026-08-01 dev cleanup dropped all 12 post-0.11.1 patches, so only the upstream-provenance question is left.
- **mesa: enable zstd compression for mesa shader** — zstd is already in the OS: `zstd:target` builds a shared `libzstd.so` (`BUILD_SHARED_LIBS=ON`, `ZSTD_BUILD_STATIC=OFF`), and `zstd` is now an explicit direct dep of mesa (`packages/graphics/mesa/package.mk:12`; `libarchive` is only a conditional dep at line 18). mesa also already has `-Dshader-cache=enabled` (line 40) but does not yet use zstd for it. So all that is left is adding `-Dzstd=enabled` to `PKG_MESON_OPTS_TARGET` — **no new library and no dependency change** (the reverted WIP `0faf137092` did both). Low-risk to redo properly.
- **linux: mac80211: spectmgmt: improve log error** — write the patch properly for upstream kernel submission.
- **mkimage: use ENV to skip creation of virtual appliance** — discussed before in a LE:master PR; just do it properly.
- **riscv** — merge the LE `tools/` commits upstream, but do NOT deploy a device build.
- **mp4v2** — move to the current 2.x version and add to `multimedia-tools`.
- **allwinner** — not ready; investigate what's needed to get a test build up on Radxa A5E.
- **rust cross-compile via meson** (https://github.com/LibreELEC/LibreELEC.tv/issues/10189) — not an LE triple bug: LE's custom `-libreelec-` rust targets (`config/path` `TARGET_NAME` + `packages/rust/rust/patches/9999-target-add-LibreELEC-target-specifications-…`) work fine with a direct `cargo build --target ${TARGET_NAME}`. The problem is meson's Cargo/rust support is **experimental** (meson [Rust docs](https://mesonbuild.com/Rust.html): Cargo subprojects "unstable and subject to change") and does not forward the target triple / `RUST_TARGET_PATH` to cargo on cross builds. Workaround in tree: glycin uses `PKG_TOOLCHAIN="manual"` + explicit `cargo build --target ${TARGET_NAME}`. Upstream case raised: https://gitlab.gnome.org/GNOME/glycin/-/work_items/185 ("Cross compile issues - meson/cargo target not passed through"). Corroborated downstream by Debian meson bug https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1091904 — `env2mfile` doesn't populate `binaries.rust` in the generated cross-file, breaking cross-compile for the same class of GNOME rust packages (glycin, bustle, gnome-tour, kooha) with "'rust' compiler binary not defined in cross file".
- **hid_mapper** — submit the cross-compile Makefile fix (`0001`, hardcoded `g++`/`gcc` → `${CXX}`/`${CC}`) upstream to s-leroux/hid_mapper. `0002` is dspinellis PR #4 and `0003`'s includes are covered by PR #3; upstream dormant since 2014 so unlikely to merge — bookkeeping.
- **nmap: submit autotools patch** — the automake-1.17 build patch (`0001-allow-build-with-automake-1-17`) has no upstream PR; submit to nmap upstream (nmap-dev) or confirm its status.
- **avahi 0.9-rc5** — WIP bump on dev (master is 0.8): drops the dbus-path backport and carries `229.patch` (upstream PR #229, open, v0.9.1 milestone) and `309.patch` (upstream PR #309, closed unmerged) for the 0.9 branch. Land/reconcile when 0.9 stabilises, and rename `229.patch`/`309.patch` to the `####-subject.patch` convention.
- **linux: aarch64: drop CONFIG_COMPAT** (https://github.com/LibreELEC/LibreELEC.tv/pull/9893) — my PR; probably split it up (per-platform) to land incrementally.
- **rpath** (lib.private via RPATH, https://github.com/LibreELEC/LibreELEC.tv/issues/7602) — main image validated clean; `tools/check-rpath` added to scan for regressions; addons still have issues. Remaining blockers: deal with **sundtek** (sundtek-mediatv) and the **JRE** addon. Note: **lbin is a separate concern** (binary placement, not RPATH) — see the lbin item below.
- **schedutil power governor** — switch `CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL=y` on all platforms. Done: Generic x86_64, Allwinner aarch64, Rockchip aarch64. Still `ondemand`: Amlogic aarch64, NXP iMX6/iMX8, Qualcomm Dragonboard, Rockchip RK3288/RK3328/RK3399, RPi/RPi2/RPi4/RPi5, Samsung. Still `performance`: Allwinner A20 (arm), Allwinner arm.
- **lbin addon files** (distinct from the rpath/#7602 work above — this is about binary *placement*, not RPATH) — addon binaries that only serve the addon itself should live in `lbin/` inside the addon directory, not in system paths like `/usr/bin`. Mirrors the `lib.private/` pattern already used for addon-private libraries (keeps `LD_LIBRARY_PATH` clean). `nextpvr` is the reference example: `hdhomerun_config` and `comskip` go to `lbin/`, `libmediainfo.so` goes to `lib.private/`. Audit all addons that install to `/usr/bin` or `/usr/sbin` and move addon-only binaries to `lbin/`.
  - **BLOCKER — `lbin` executables lose the execute bit (revisit this mess).** Kodi's addon-install unzip does not preserve the execute bit, and `packages/mediacenter/kodi/scripts/service-addon-wrapper` only `chmod +x`'s `${ADDON_PATH}/bin/*` on enable/post-install — **not `lbin/`**. So any binary in `lbin/` that must *run* ends up non-executable and fails (verified 2026-07 building the lldpd addon; lldpd/lldpcli had to stay in `bin/`). As it stands `lbin/` is only safe for non-executable private files, or the addon must `chmod +x` its own `lbin/*` (e.g. in the `.start` script). This means the "move addon-only binaries to `lbin/`" plan can't work as written — either extend `service-addon-wrapper` to also `chmod +x lbin/*`, or have addons chmod their own. **Check whether `nextpvr`'s `lbin` `comskip`/`hdhomerun_config` actually run** — they may be latently broken or chmod'd elsewhere. Until resolved, keep runnable addon binaries in `bin/`.
- **sccache** — use for caching build-host compilation; analogous to mesa-reusable (pre-built mesa host tools) but for the full toolchain / host packages. Prior WIP: PR https://github.com/LibreELEC/LibreELEC.tv/pull/5162 (`tools/generate-toolchain` script — packages a versioned aarch64 GCC toolchain as a tarball with SHA256 for distribution). Also: a hacky dev-branch experiment tarring up a built toolchain and validating via hash. End goal: `USE_REUSABLE_TOOLCHAIN=yes` style flag that downloads a pre-built toolchain tarball (same model as mesa-reusable) instead of compiling it from source — needs proper fallback/check logic (mesa-reusable approach needs improvement in this area too).

### Obsolescence

- **syslinux** — dead/unmaintained; replacing with systemd-boot for LE13 (UEFI-only agreed). systemd already builds `systemd-boot.efi` for Generic (`-Dbootloader=enabled`, commit `3c8c56c8`); not yet wired into `scripts/mkimage`. See `syslinux-replacement.md` for full investigation notes.
- **udevil** — goal is a minimal device-mount system without bloatware (udisks3 is too heavy). Migrated from dead original (ignorantguru) to maintained fork `arnie97/udevil-ng` (https://github.com/arnie97/udevil-ng); currently pinned to git hash `666e443c`. End state TBD: evaluate whether udevil-ng is the right long-term minimal solution, or whether a lighter custom approach exists.
- **pkg-config → pkgconf** — migrate `packages/devel/pkg-config` (0.29.2, last release 2017) to pkgconf (https://github.com/pkgconf/pkgconf/, latest 2.5.1 June 2025). pkgconf is a drop-in replacement but NOT bug-compatible — stricter standards compliance. Known issue: pkgconf (and pkg-config) does not honour `Libs.private` for static linking in cross-compile builds — packages use workaround hacks (see https://github.com/LibreELEC/LibreELEC.tv/issues/5952; partial fixes in mpd PR#9628 and elfutils PR#9621). Migration must also resolve the `Libs.private` static-linking problem. Migration notes: (1) autotools build; (2) add symlink `pkg-config → pkgconf` in `post_makeinstall_host`; (3) set `--with-system-libdir`, `--with-system-includedir`, `--with-pkg-config-dir` for cross-compile paths; (4) strict `.pc` validation may expose masked issues in third-party packages — document first, then attempt build-wide.

### Retire / Replace

- **Docker iptables → nftables** — move Docker to native nft (still experimental; target LE14+). Note the boot-log line `bridge: filtering via arp/ip/ip6tables is no longer available by default. Update your scripts to load br_netfilter if you need this.` — Docker containers work regardless (veths join `docker0` and reach forwarding state), but bridge-level iptables filtering for container isolation silently won't apply unless `br_netfilter` is loaded. Fold this into the nft migration rather than fixing in isolation.
- **iptables** — drop completely once nft transition is complete
- **gold linker** — retire gold linker support (https://github.com/LibreELEC/LibreELEC.tv/issues/11242); LE14 work.

### Platforms

- **Allwinner H700/H618 (sun50iw9/sun50iw10) — A523 SoC** — add support
- **Qualcomm** — fix broken platform support
