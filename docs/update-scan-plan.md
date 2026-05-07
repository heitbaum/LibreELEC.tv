# update-scan — noise classification and per-package plan

`tools/update-scan` compares each package's `PKG_VERSION` against an upstream
source (release-monitoring.org / Anitya for most, the GitHub API for git-hash
packages). Historically it reported every string difference, so the output was
dominated by false positives. This document records:

1. the **generic** classification the tool now performs, and
2. the **per-package knowledge** that generic logic cannot infer — much of it
   hard-won maintainer knowledge about how each upstream versions its releases.

The long-term direction is a per-package config field (a `PKG_UPDATE_SCAN=...`
hint in `package.mk`, or a data table here) so this knowledge lives next to the
package and the tool consumes it, rather than accreting `case` arms.

## Status & how to resume (last updated 2026-07-05)

**Done:** the generic classification below is implemented in `tools/update-scan`
(functions `normalise_version`, `is_plain_version`, `is_prerelease`,
`cosmetic_equal`, `upstream_strictly_newer`; the classify/print block at the end
of `check_for_update`; per-package cosmetic arms in the RMO `case` block; the
`PACKAGES_PRERELEASE` summary). Validated offline against the labelled snapshot
in the appendix — all cases matched the intended verdict.

**Not done:** everything in "Per-package plan" below — these need per-package
data/config, not more generic logic. Pick them up one mechanism at a time.

**How to test a change** (no network needed): extract the pure functions and run
them against the appendix snapshot.

```bash
tr -d '\r' < tools/update-scan | \
  sed -n '/^normalise_version() {/,/^}/p;/^is_plain_version() {/,/^}/p;/^is_prerelease() {/,/^}/p;/^cosmetic_equal() {/,/^}/p;/^upstream_strictly_newer() {/,/^}/p' > /tmp/fns.sh
source /tmp/fns.sh
# then assert cosmetic_equal / is_prerelease / upstream_strictly_newer per row
```

For a real run: `tools/update-scan [PKG …]` (needs `github_token`/`github_user`
in `~/.libreelec/options` for the git-hash packages). `PRERELEASE=yes` shows the
suppressed pre-releases; `AUTO_UPDATE=yes` is the CI/bot output (strictly-newer
stable only).

## Generic classification (implemented)

For **plain** version strings (not a git hash, not the multi-field GitHead/TAG
output, not an nvidia `x (y)` string, not a `! … !` tracker error):

| Class | Rule | Action |
|-------|------|--------|
| cosmetic-equal | equal after `normalise_version` (strip leading `v`, zero-pad) + per-package cosmetic strip | **current** — not shown |
| pre-release | `is_prerelease` matches upstream (`rc`/`alpha`/`beta`/`-dev`/PEP440 `aN`/`bN`/`-b.N`/`ALPHA_`/…) | **suppressed** — listed under "Upstream pre-release only"; `PRERELEASE=yes` shows them |
| update | upstream strictly newer via `sort -V` | shown |
| local-newer / older-upstream | upstream differs but is **not** newer | **shown in the human table** (a stale/broken tracker lookup or a local test build worth a human look); the `AUTO_UPDATE` bot ignores it so it never opens a downgrade PR |

`normalise_version` only does transforms that are safe for **every** package
(leading `v`, zero-padding). Meaning-dependent suffixes (`-RELEASE`, `+dfsg`,
Anitya `-N`, snapshot dates) are **not** stripped globally — e.g. ncurses
`6.6-20260704` is a real newer snapshot, not cosmetic. Those go per-package.

The `AUTO_UPDATE` (CI bot) path additionally requires **strictly newer** and
non-pre-release, so it can never open a downgrade or pre-release PR.

### Per-package cosmetic (in the `case` block)

| Package | Rule | Reason |
|---------|------|--------|
| krb5 | strip `-final` | Anitya formatting |
| lm_sensors | `-` → `.` | Anitya formatting |
| boost | strip trailing `-N` | Anitya packaging release (`1.91.0-1`) |
| libsodium | strip `-RELEASE` | upstream tag suffix (`1.0.22-RELEASE`) |

## Per-package plan (not yet automated)

The rest of the scan noise needs one of the mechanisms below. Packages grouped
by the mechanism required, with the maintainer's note.

### A. Pin to a major series (like the existing nvidia special-case)

The upstream latest is a newer *major* that we deliberately do not track.

| Package | Track | Note |
|---------|-------|------|
| qt5 | v5 | we track v5 (upstream latest is qt6) |
| mariadb | LTS | we track the LTS version |
| groovy | v4 | track v4, not "any" (latest is 6.x ALPHA) |
| pngquant | v2 | 2.x is C, 3.x is rust — we use v2 |
| encfs | v1 | v1 is C, v2 is rust — they are different; we use v1 |
| fuse | v2 | this is fuse 2, which is EOL |
| mp4v2 | v2 | v2 is the right release — on the packaging worklist |
| protobuf | ? | cannot upgrade — packaging arrangement changed; worklist item |

### B. Track a git repo's tags/releases (not Anitya)

We pin a git hash from a specific repo; Anitya's number is wrong or irrelevant.
Ideally the tool reads the repo's tags/releases and reports a version again when
upstream retags.

| Package | Note |
|---------|------|
| cxxtools | moved to the git repo (v3 obsolete); want a version number again when upstream retags; need to track the GitHub repo's releases |
| tntnet | same as cxxtools |
| dbussy | git hash from GitLab now — do not expect a version number (but it could return) |
| libmad | tracking a git repo as the main one is not maintained |
| libprojectM | tracking a git repo; relationship to the upstream release unclear |
| media-driver | we track the tags |
| x264 | PIA — want to always be current; need the git hash from the repo (see `update-pkg`) |
| xf86-video-intel | same as x264; it is a git hash but need the hash from the upstream repo — package is effectively obsolete |
| kmsxx | probably need to bump |
| tm16xx-display | hoping for upstream, but no movement |
| hyperhdr-* (lunasvg, mdns, nanopb, qmqtt, sdbus-cpp, stb) | git-hash sub-packages; overall hyperhdr compatibility matrix unclear |

### C. Track Kodi's repo (Kodi manages the versioning)

| Package | Note |
|---------|------|
| libdvdcss | Kodi manages the versioning — target their repo, not release-monitoring |
| libdvdnav | as above |
| libdvdread | as above |

### D. Snapshot/patch level is optional — the base version is "green"

An always-incrementing snapshot/patch tail; the base version is fine and the
snapshot is only taken for compatibility/other reasons.

| Package | Note |
|---------|------|
| ncurses | always-incrementing; `6.6` is green, `6.6-YYYYMMDD` might be used for compatibility |
| vim | same as ncurses (`9.2.NNNN` patch level) |

### E. Scan-ignore (out of our hands / dev-only / neglected)

Candidates for a per-package "do not scan" opt-out.

| Package | Note |
|---------|------|
| rpi-eeprom | HiassofT does this — I take no notice |
| spirv-headers | special case, only bumped when llvm/glslang require it |
| spirv-tools | as above |
| tigervnc | we don't do anything with this |
| libatasmart | a local `:dev` thing — do not code around it |
| crazycat | stale (tracker returns the literal "latest") |
| radeontop | haven't looked at this for ages |
| rkbin | haven't looked at this for ages |

### F. Broken / wrong upstream lookup

| Package | Note |
|---------|------|
| memtester | release-monitoring is broken at reporting this repo's version |
| mesa-reusable | version is `${…}` (unexpanded); should check `github.com/LibreELEC/mesa-reusable` instead |

### G. Coupled version

| Package | Note |
|---------|------|
| heimdal | must match samba — we run the latest that samba's embedded build needs |
| spirv-headers / spirv-tools | coupled to llvm / glslang (see E) |

### H. To investigate

| Package | Note |
|---------|------|
| buildx | not sure how to update |
| flatbuffers | no idea whether `25.12.19` and `25.12.19-<date>-<hash>` are the same |
| opencaster | no idea (`3.2.2` vs `3.2.2+dfsg`) |
| pycparser | **resolved** — no separate `3.00` release exists; PyPI serves `3.0` (`pycparser-3.0.tar.gz`, PEP 440 normalises `3.00`→`3.0`), Anitya just reports the raw `3.00` tag. LE is already current; the zero-pad `cosmetic_equal` correctly marks it current |
| volk | no idea — maybe we should bump |
| usbmuxd | check whether we can update — should be on the normal cycle |
| wlan-firmware | need to check the state of this |
| iftop | believed to be the last of iftop — is there a newer repo to track? |
| tvheadend43 | waiting for upstream to confirm the breaking changes are done |
| steamlink-ffmpeg | no idea |

## Implementing the remaining mechanisms

Concrete starting points for each class above:

- **A. Pin to major series** — the template already exists: the
  `nvidia|xf86-video-nvidia` arm of the `case` in `check_for_update` takes
  `pkg_major="${PKG_VERSION%%.*}"`, pulls the Anitya project's `versions[]`,
  filters `startswith("${pkg_major}.")`, `sort -V | tail -1`, and shows the
  overall latest in brackets. Generalise it: drive the major (or an
  arbitrary "track this series" predicate) from per-package config rather than
  a hardcoded package name. mariadb needs "LTS series" not just major; protobuf
  changed its numbering/packaging entirely (worklist — may just become
  scan-ignore until we decide).

- **B. Track a git repo's tags/releases** — the 40-hex git-hash path already
  queries the GitHub API for the default-branch HEAD and `/tags`. Two gaps:
  (1) **tag selection** takes `.[0]` from `/tags` unsorted, so it shows ancient
  junk — sort by commit date or `-V`; (2) packages that pin a **fork/mirror**
  (x264, xf86-video-intel, libmad, libprojectM, media-driver) need a per-package
  "upstream repo" override because `PKG_URL` points at the tracked repo, not the
  place new versions appear. dbussy is **GitLab**, so a GitLab tags/commits path
  is needed (or accept "githash only, no version").

- **C. Track Kodi's repo** — libdvdcss/libdvdnav/libdvdread use Kodi's tag
  scheme (`1.4.3-Next-Nexus-Alpha2-2`); point the lookup at Kodi's repo tags
  instead of Anitya, or scan-ignore and bump with Kodi.

- **D. Snapshot/patch optional** — per-package cosmetic in the `case` block:
  ncurses strip a trailing `-YYYYMMDD` so `6.6-…` reads equal to `6.6`; vim
  compare on `major.minor` only (patch level `9.2.NNNN` is a rolling snapshot).
  Only do this where the base version is genuinely "green".

- **E. Scan-ignore opt-out** — add a per-package skip (e.g. `PKG_UPDATE_SCAN="no"`
  read from `package.mk`, or a skip-list in the tool) and add those packages to
  a `PACKAGES_SKIPPED` summary so they are visible but out of the main table.

- **F. Broken lookup** — memtester: investigate the release-monitoring project
  mapping for LibreELEC (Anitya returns an older version); may need a project-id
  override. mesa-reusable: the `${` skip stops the noise, but ideally check the
  `LibreELEC/mesa-reusable` GitHub releases for the real answer.

- **G. Coupled version** — heimdal tracks whatever samba's embedded build needs;
  spirv-headers/spirv-tools only move when llvm/glslang do. Practically these
  are scan-ignore + a manual bump alongside their partner.

## Appendix: labelled scan snapshot (2026-07-05)

Ground-truth from a real `tools/update-scan` run, hand-labelled by the
maintainer. Use as the regression fixture for the generic logic. Codes:
`u` update wanted · `r` equivalent · `p` pre-release · `s` stale · `t` testing ·
`?` needs investigation (see per-package notes above).

```
u  aspnet10-runtime  10.0.2                | 10.0.9
u  bindgen-cli       0.72.0                | 0.72.1
r  boost             1.91.0                | 1.91.0-1
p  cryptsetup        2.8.6                 | 2.8.7-rc1
u  filebrowser       2.63.17               | 2.63.18
r  firmware-imx      8.31-4fa5b46          | 8.31
?  flatbuffers       25.12.19              | 25.12.19-2026-02-06-03fffb2
u  flit              3.12.0                | 4.0.0
u  fwupd             2.0.19                | 2.1.6
?  groovy            4.0.32                | 6_0_0_ALPHA_1        (A: track v4)
p  hyperhdr          21.0.0.0              | 22.0.0.0beta2
p  jellyfin          10.11.11              | 12.0-rc2
pt libfyaml          v1.0.0-alpha7         | 1.0.0-alpha7
u  libgpiod          2.3                   | 2.3.1
r  libsodium         1.0.22                | 1.0.22-RELEASE
p  libtool           2.6.0                 | 2.5.4                (t: local dev)
p  libvpx            1.16.0                | 1.17.0-rc1
u  lvm2 / lvm2-lib   2.03.40               | 2.03.41
p  lxml              6.1.1                 | 7.0.0a3
u  makemkv / -bin    1.18.2                | 1.18.4
?  mariadb           12.3.2                | 13.0.1               (A: track LTS)
?  media-driver      26.2.4                | 26.1.5               (B: track tags)
?  memtester         4.7.1                 | 4.5.1                (F: Anitya broken)
?  mesa-reusable     ${…}                  | 26.1.4              (F: ${ skipped)
?  mp4v2             5.0.1                 | 2.1.3                (A: track v2)
?  ncurses           6.6                   | 6.6-20260704        (D: snapshot)
p  nqptp             1.2.8                 | 1.2.9-dev
u  ntfs-3g_ntfsprogs 2022.10.3             | 2026.2.25
p  nvme-cli          2.16                  | 3.0-b.2
u  oneDNN            3.5.3                 | 3.12.2
?  opencaster        3.2.2                 | 3.2.2+dfsg
u  plymouth          24.004.60             | 26.134.222
?  pngquant          2.18.0                | 3.0.3                (A: track v2)
p  proftpd           1.3.10rc2             | 1.3.10rc1
?  protobuf          21.12                 | 35.1                 (A/worklist)
r  pycparser         3.0                   | 3.00                 (resolved)
?  qt5               5.15.19               | 6.12.0-beta1         (A: track v5)
u  setuptools-scm    9.2.1                 | 10.2.0
p  shairport-sync    5.1                   | 5.2-dev
u  tailscale         1.98.4                | 1.98.8
?  tigervnc          1.10.1                | 1.16.2               (E: ignore)
u  udisks            2.10.1                | 2.11.1
?  vim               9.2.0                 | 9.2.0782             (D: snapshot)
?  volk              1.4.350               | 1.4.350.1
p  weston            15.0.1                | 15.0.92     (numeric pre-rel; no marker, still shows)
u  zfs               2.4.0                 | 2.4.3
```

Git-hash / multi-field rows (fall through `is_plain_version` to plain
inequality; handled by mechanisms B/C/E, not the generic filter): crazycat,
cxxtools, dbussy, digital_devices, driverselect, encfs (beta → `p`), fuse,
heimdal, hyperhdr-*, iftop, kmsxx, libatasmart, libdvdcss/nav/read, libmad,
libprojectM, radeontop, rkbin, rpi-eeprom, spirv-headers, spirv-tools,
steamlink-ffmpeg, tm16xx-display, tntnet, tvheadend43, usbmuxd, wlan-firmware,
x264, xf86-video-intel.

> Known generic-logic gap: **weston** encodes a pre-release numerically
> (`15.0.92` = pre-15.1) with no textual marker, so `is_prerelease` cannot catch
> it — it still shows. Left as-is; special-case only if it becomes a nuisance.
