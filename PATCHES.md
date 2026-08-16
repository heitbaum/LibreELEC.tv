## Patch Tracking

Every patch carried in `master` must be classified. The goal is to avoid accumulating patches: either submit fixes upstream or explicitly declare them intentionally local.

> **Last reconciled with the tree:** upstream/master `6dab8beb89`, dev re-checked after the 2026-08-01 cleanup. Run `tools/patch-scan.py --ref upstream/master` — the default `master` ref is a local branch that lags behind a fetch. Nothing is untracked in either direction, but as of 2026-08-03 the scan reports 2 stale rows: the two `devel/libcec` gcc-16 rows under "Pending upstream submission" name patch files that are in neither tree (`packages/devel/libcec/patches/` is empty and libcec is now on 8.1.3) — resubmit or drop those rows. The cleanup dropped dev's libwebsockets revert (dev is on 5.0.0 with the const patch, same as master), the 11 carried libtool commits (dev re-landed 2.6.2), all 12 post-0.11.1 libaacs patches (dev is on 0.12.0, unpatched) and the mesa addrlib patch — those rows are gone. Dev now carries 36 patches that master does not (35 at the reconcile, plus the x265 asm-objects fix added 2026-08-03); master carries 2 that dev does not (avahi `0001-dbus`, grub `0001-build-fix`, both annotated on their rows). No "drop on a release past X" threshold has been reached.

### Status codes

| Code | Meaning |
|------|---------|
| `le-specific` | Intentionally local — LibreELEC-specific change (paths, config, behaviour) that cannot or should not go upstream |
| `backport` | Cherry-picked from an upstream commit; drop when the package is updated past the included fix |
| `pending` | Should be submitted upstream; not yet submitted |
| `submitted` | PR or patch submitted; awaiting upstream merge |
| `needs-triage` | Not yet classified |

### Pending upstream submission

Patches that should be sent to the upstream project but have not yet been submitted:

| Package | Patch | Notes |
|---------|-------|-------|
| binutils | `0002-binutils-2-39-dont-error-on-missing-makeinfo.patch` | Skip makeinfo when not installed |
| binutils | `0003-libctf-gcc-16.patch` | gcc-16 ctf.h build fix |
| v4l-utils | `0999-pending-t2-descriptor.patch` | ETSI EN 300 468 T2 delivery-system descriptor freq fix |
| addons/addon-depends/argtable2 | `0001-fix-gcc-14-build.patch` | gcc-14 build fix |
| addons/addon-depends/comskip | `arg3.patch` | Rudi Heitbaum — build against argtable3 instead of the dead argtable2 (comskip's `PKG_DEPENDS_TARGET` already uses argtable3); **dev only**, no upstream PR yet, and needs renaming to the `####-subject.patch` convention |
| addons/addon-depends/ffmpegx | `0001-fix-NULL-dereference-if-no-frames-before-end-of-strea.patch` | NULL dereference in demuxer |
| addons/addon-depends/icu | `0001-ldflags.patch` | Comment out -nodefaultlibs/-nostdlib that break cross-compile |
| addons/addon-depends/multimedia-tools-depends/opencaster | `0001-headers.patch` | Use linux/if_tun.h |
| addons/addon-depends/multimedia-tools-depends/opencaster | `0003-fix-gcc-14-build.patch` | gcc-14 build fix |
| addons/addon-depends/multimedia-tools-depends/tstools | `0001-build.patch` | Add .PHONY builddirs target |
| addons/addon-depends/multimedia-tools-depends/tstools | `0002-crossstrip.patch` | Use ${CROSS_COMPILE}strip |
| addons/addon-depends/multimedia-tools-depends/tstools | `0044-fix-gcc15-build.patch` | gcc-15 build fix |
| addons/addon-depends/network-tools-depends/iftop | `0001-Fix-building-with-gcc10.patch` | gcc-10 build fix |
| addons/addon-depends/network-tools-depends/iftop | `0002-fix-pcap-detection-and-use-ncurses.patch` | Fix pcap detection, link ncurses |
| addons/addon-depends/network-tools-depends/iftop | `0003-fix-pcap-filter-symbol-conflict.patch` | Rename pcap_filter to avoid symbol conflict |
| addons/addon-depends/qt5 | `0002-QSslSocket-make-it-work-with-OpenSSL-v4.patch` | OpenSSL v4 QSslSocket fix |
| addons/addon-depends/snapcast-depends/aixlog | `0019-build-with-cmake-4.0.0.patch` | CMake 4.0 build fix |
| addons/addon-depends/system-tools-depends/st | `0001-le-fixes.patch` | Use XParseColor for #rrggbb colours (XftColorAllocName bug) |
| network/wsdd-native | `0001-dlopen-libsystemd-by-soname-not-configure-time-path.patch` | Rudi Heitbaum — `find_library()` bakes the configure-time absolute path into the binary as the `dlopen()` argument, so a cross build loads a sysroot path that does not exist on the target and the daemon exits under `--systemd`; to submit to gershnik/wsdd-native |
| addons/addon-depends/ttyd-depends/libwebsockets | `0001-tls-openssl-build-with-the-constified-X509-name-acce.patch` | Rudi Heitbaum — OpenSSL 4 constified `X509_get_subject_name()`/`X509_get_issuer_name()`, breaking lws's own `-Werror -Wignored-qualifiers` TLS build; unfixed on upstream `main`; to submit to warmcat/libwebsockets. Carried with libwebsockets 5.0.0 on both master and dev, which also needs `-DLWS_WITH_HTTP3=OFF` since 5.0.0 otherwise force-selects GnuTLS |
| addons/addon-depends/vdr-plugins/vdr-plugin-dvbapi | `0001-crosscompiling.patch` | Build FFdecsa.o target not all in cross-compile |
| addons/addon-depends/vdr-plugins/vdr-plugin-epgsearch | `0001-don-t-build-unused-plugins.patch` | Skip unused plugin binaries |
| addons/addon-depends/vdr-plugins/vdr-plugin-streamdev | `0001-support-locale-i18n.patch` | Add install-i18n to make targets |
| addons/addon-depends/vdr-plugins/vdr-plugin-xmltv2vdr | `0001-add-required-include-for-vdr-plugin-xmltv2vdr-0.2.2.patch` | Missing VDR include path for 0.2.2 |
| addons/addon-depends/vdr-plugins/vdr-plugin-xmltv2vdr | `0002-fix-epgdata2xmltv-static-linking-issue.patch` | Matthias Reichl — static-link epgdata2xmltv (pkg-config --static) |
| addons/service/boblightd | `0001-add-missing-getopt-includes.patch` | Missing unistd.h for getopt |
| addons/service/hyperion | `0001-fix-build-with-python-313.patch` | Python 3.13 build fix |
| addons/service/hyperion | `0002-build-with-cmake-4.0.0.patch` | CMake 4.0 build fix |
| addons/service/hyperion | `0003-fix-protobuf-cmake.patch` | Fix Protobuf CMake variable case |
| addons/service/lcdd | `0001-add-dm140-vfd-support.patch` | Add DM140 VFD driver support |
| addons/service/mariadb | `0002--fix-gcc14-build.patch` | gcc-14 build fix |
| addons/service/minidlna | `0002-fix-channel-layout-api-for-ffmpeg7.patch` | FFmpeg 7 channel layout API change |
| addons/service/oscam | `0001-link-with-ludev.patch` | Link against libudev |
| addons/service/oscam | `0002-pcsc-pthread.patch` | Link pcsclite with pthread |
| audio/libsndfile | `1073-build-with-cmake-4.0.0.patch` | CMake 4.0 build fix |
| audio/sidplay-libs | `0001-m4-tests.patch` | Fix old-style C++ headers in m4 tests |
| audio/sidplay-libs | `0002-inherited.patch` | Add `this->` to fix dependent names in templates |
| audio/sidplay-libs | `0003-operator.patch` | Remove redundant class qualification in operator= |
| audio/sidplay-libs | `0004-includes.patch` | Missing include fix |
| audio/soxr | `0001-build-with-cmake-4.0.0.patch` | CMake 4.0 build fix |
| compress/lzo | `0001-build-with-cmake-4.0.0.patch` | CMake 4.0 build fix |
| compress/xz | `0001-init-uninitialized-variables.patch` | Initialise uninitialised variables |
| debug/gdb | `0002-remove-tex-dependencies.patch` | Skip makeinfo in missing script (no TeX in build env) |
| debug/memtester | `0001-cross-compile.patch` | Use $CC instead of hardcoded cc |
| debug/strace | `0002-fix-autoconf-archive.patch` | Fix autoconf-archive 2019 API change |
| emulation/libretro-bsnes-mercury-performance | `0001-fix-cross-compile.patch` | Remove -O3 for cross-compile |
| emulation/libretro-cannonball | `0041-Set-the-c--17-standard.patch` | Force C++17; code fails with C++20 |
| emulation/libretro-dosbox-pure | `0001-Makefile-optimization-and-libs.patch` | Makefile build fixes |
| emulation/libretro-dosbox-pure | `0002-cross-compile-fix.patch` | Cross-compile build fix |
| emulation/libretro-mame2010 | `0001-dont-force-objdump.patch` | Don't hardcode objdump binary |
| emulation/libretro-mupen64plus-nx | `0001-Enable-all-options.patch` | Enable all libretro core options |
| emulation/libretro-mupen64plus-nx | `0002-Working-Defaults.patch` | Set working default options |
| emulation/libretro-mupen64plus-nx | `0003-Fix-compiler-error-with-GCC-15.patch` | GCC 15 missing uint32_t include |
| emulation/libretro-mupen64plus-nx | `0004-Fix-compiler-error-on-Windows.patch` | Guard rand_s for non-Windows builds |
| emulation/libretro-picodrive | `0001-remove-temporary-getoffs.patch` | Remove temporary getoffs build helper |
| emulation/libretro-scummvm | `0001-Fix-missing-library-version.patch` | Missing library version constant |
| emulation/libretro-scummvm | `0002-Move-scummvm.ini-to-writable-save-directory.patch` | Use writable save dir for scummvm.ini |
| emulation/libretro-scummvm | `0003-fix-armv7-GCC-15.1-internal-compiler-error.patch` | GCC 15.1 armv7 internal compiler error |
| emulation/libretro-stella | `0001-do-not-use-static-libgcc-libstdc++.patch` | Don't use static libgcc/libstdc++ |
| graphics/glew | `0001-fix-pkgconf.patch` | Fix libdir to use exec_prefix-relative path in glew.pc (cross-compile pkgconf fix) |
| graphics/vulkan/vkmark | `0001-fix-sysroot.patch` | Fix sysroot-relative path for vk.xml lookup in meson.build |
| graphics/vulkan/vulkan-tools | `9951-cmakelists-opts.patch` | Add CMake options for WSI backend selection (XCB/Xlib/Wayland/DirectFB) |
| lang/llvm | `0001-14.0.0-force-disable-cmakelist-options.patch` | Disable LLVM benchmark generation (LLVM_INCLUDE_BENCHMARKS=OFF) |
| linux-firmware/rtl8723bs_bt | `0001-Makefile.patch` | Cross-compile Makefile fixes (use $CC/$CFLAGS/$LDFLAGS, DESTDIR install) |
| linux-firmware/rtl8723bs_bt | `0002-firmware-path.patch` | Fix firmware filename from rtlbt_fw to rtl8723b_fw |
| multimedia/ffmpeg | `postproc/0001-postproc.patch` | Add libpostproc source plugin |
| multimedia/ffmpeg | `v4l2-drmprime/0001-v4l2-drmprime.patch` | V4L2 m2m DRM-Prime output support for ARM hardware |
| multimedia/ffmpeg | `v4l2-request/0001-v4l2-request.patch` | V4L2 Request API hardware decode support (13-patch set) |
| multimedia/ffmpeg | `vf-deinterlace-v4l2m2m/0001-vf-deinterlace-v4l2m2m.patch` | V4L2 m2m deinterlace filter |
| multimedia/ffmpeg | `detlev/0001-wip-hevc-Add-support-for-sps-st-rps-control.patch` | WIP HEVC SPS short-term RPS control |
| multimedia/intel-vaapi-driver | `0001-meson-raise-meson_version-to-0.60.0.patch` | Rudi Heitbaum — raise meson_version to 0.60.0; to submit to the irql-notlessorequal fork |
| multimedia/intel-vaapi-driver | `0002-meson-check-git-describe-return-code-and-use-project.patch` | Eli Schwartz — run_command check + project_source_root; to submit to the fork |
| multimedia/intel-vaapi-driver | `0003-meson-replace-deprecated-get_pkgconfig_variable-with.patch` | Rudi Heitbaum — get_variable() for deprecated get_pkgconfig_variable; to submit to the fork |
| multimedia/intel-vaapi-driver | `0004-gen9_hevc_encoder-fix-array-bounds-in-brc_update_set.patch` | Rudi Heitbaum — fix -Warray-bounds in gen9 hevc brc_update_set_constant; to submit to the fork |
| multimedia/zvbi | `0001-fix-static-linking.patch` | Fix static linking: move libpng before LIBS in LIBS assignment |
| multimedia/zvbi | `0002-gettext.patch` | Update AM_GNU_GETTEXT_VERSION to 0.24 |
| multimedia/zvbi | `0003-ssize-max.patch` | Remove unnecessary SSIZE_MAX overflow checks |
| multimedia/zvbi | `0004-fix-clang-support.patch` | Remove deprecated #cpu i386/i686 undef hacks |
| print/freetype | `0001-fix-pkgconf.patch` | Fix exec_prefix-relative paths in freetype2.in (cross-compile pkgconf fix) |
| security/libgcrypt | `0001-add-patch-so-sed-will-not-replace-parts-of-paths.patch` | Fix sed regex to avoid accidentally replacing parts of paths containing -O |
| security/nss | `0001-3.15.5-standalone-1.patch` | Add nss.pc and nss-config script; allow standalone build without NSPR in tree |
| security/nss | `0004-fix-build-of-cmd-with-nssutil.patch` | Add missing -lnssutil to link flags for cmd/ build |
| sysutils/fuse | `0001-aarch64-support.patch` | Add aarch64 support: use linux/types.h for u64/u32 definitions |
| sysutils/fuse | `0003-fix-configure-ac.patch` | Add AM_GNU_GETTEXT configuration to configure.ac |
| sysutils/keyutils | `0001-cflags.patch` | Change CFLAGS := to += for proper external flag accumulation |
| sysutils/kmod | `0001-fix-pkgconf.patch` | Fix pkgconf: use ${variable} references instead of @variable@ |
| sysutils/libhid | `0001-0.2.16-automake-1.13.patch` | Update AM_CONFIG_HEADER to AC_CONFIG_HEADERS for automake 1.13 |
| sysutils/libhid | `0003-use-pkgconfig.patch` | Replace deprecated libusb-config with pkg-config |
| sysutils/lirc | `0001-pluginszotac-fix-poll-timeout.patch` | Fix zotac plugin poll timeout (0 → -1 for infinite wait) |
| sysutils/pciutils | `0001-fix-pkgconf.patch` | Fix pkgconf: use ${variable} references |
| sysutils/util-linux | `0001-fix-pkgconf.patch` | Fix pkgconf files (blkid, mount, smartcols, uuid) to use ${variable} refs |
| sysutils/util-linux | `0002-fix-gettext.patch` | Update AM_GNU_GETTEXT_VERSION to 0.24 |
| devel/automake | `0001-fix-help2man.patch` | Add --no-discard-stderr to help2man invocation |
| devel/binutils | `0003-libctf-gcc-16.patch` | Fix GCC 16 compat: add CTF_K_DECL_TAG and CTF_K_TYPE_TAG defines |
| devel/cmake | `0001-disable-free-comp-methods.patch` | Disable SSL_COMP_free_compression_methods for OpenSSL 1.1+ |
| devel/elfutils | `0001-make-executables-optional.patch` | Add --enable-programs flag (defaults to disabled) |
| devel/flex | `0001-use-flex-host-for-target-cross-compile.patch` | Use host flex binary for target cross-compile (replaces sed dance) |
| devel/intltool | `0001-fix-regex-expressions.patch` | Fix Perl regex escaping (${ in character classes) in intltool-update.in |
| devel/libbpf | `0001-fix-crosscompile-and-sysroot.patch` | Fix sysroot-relative prefix in .pc and add -lz to Libs |
| devel/libcec | `0001-use-snprintf-in-FindAdapters-for-nul-termination.patch` | Rudi Heitbaum — snprintf in FindAdapters to fix gcc-16 -Wstringop-truncation; to submit to Pulse-Eight/libcec |
| devel/libcec | `0002-size-cecc-client-port-buffer-to-full-length.patch` | Rudi Heitbaum — enlarge cecc-client g_strPort to 1024 to fix gcc-16 -Wformat-truncation; to submit to Pulse-Eight/libcec |
| devel/libconfuse | `0001-gettext-0.20-libconfuse.patch` | Add AM_GNU_GETTEXT_REQUIRE_VERSION for gettext compat |
| devel/libffi | `0001-Fix-installation-location-of-libffi.patch` | Install to lib instead of toolexeclib (multilib cross-compile fix) |
| devel/libffi | `0002-fix-pkgconf.patch` | Fix pkgconf: use ${libdir} instead of ${toolexeclibdir} |
| devel/libftdi1 | `0001-build-with-cmake-4.0.0.patch` | Fix project name path inconsistency when FTDIPP is set |
| devel/libirman | `0001-fix-poll-include.patch` | Add AC_CHECK_HEADERS for poll.h/sys/poll.h |
| devel/libtool | `0001-prevent-libtool-to-linking-against-host-libs-on-make.patch` | Prevent libtool linking against host libs during make install (sysroot) |
| devel/ncurses | `0002-alloc-fallbacks.patch` | Fix memory management for fallback terminfo entries |
| devel/ncurses | `0003-fix-configure-pkgconfig.patch` | Fix cross-compile pkg-config path check (test -d → test -n) |
| devel/pkg-config | `0001-Add-support-for-multiple-sysroots.patch` | Add PKG_CONFIG_SYSROOT_BASE env var for multiple sysroots |
| devel/pkg-config | `0002-Do-not-use-bool-as-a-field-name.patch` | Rename bool field to boolean (C99/C23 reserved keyword) |
| devel/quilt | `0001-add-git-style-diff-support.patch` | Add --git option to quilt diff/refresh for git-style patches |
| devel/quilt | `0002-use-git-diff-for-content-in-git-mode.patch` | Use git diff --no-index for content in --git mode |
| devel/readline | `0001-display-null-prompt.patch` | Add null check for prompt_invis_chars to prevent SIGSEGV |
| textproc/xmlstarlet | `0246-fix-compile-with-libxml-2-12-0.patch` | Fix build with libxml2 2.12.0 (remove xmlCleanupGlobals, add headers) |
| textproc/xmlstarlet | `0900-fix-compile-with-libxml-2-14-0.patch` | Fix build with libxml2 2.14.0 (ATTRIBUTE_UNUSED definition) |
| tools/crust | `0001-configs-Make-all-H6-devices-use-I2C-PMIC.patch` | Add I2C PMIC config for Allwinner H6 devices (beelink_gs1, orangepi_3) |
| tools/hdparm | `0001-9.42-cflags.patch` | Remove hardcoded -O2 -W from CFLAGS (let build system control) |
| tools/syslinux | `0002-fix-build-with-glibc-2.36.patch` | Fix glibc 2.36 compat: define linux/fs.h constants directly |
| wayland/lib/seatd | `0001-add-option-to-specify-seatd-path.patch` | Add -p option to specify custom seatd executable path |
| x11/driver/xf86-video-intel | `1001-prefer-iris-and-crocus-over-i965.patch` | Prefer iris/crocus drivers over legacy i965 for AMD/Intel GPUs |
| x11/other/fluxbox | `0001-hack-avoid-potential-SIGFPE-in-Menu-updateMenu.patch` | Fix potential SIGFPE in Menu::updateMenu() |
| x11/other/fluxbox | `0002-hide-useless-errors.patch` | Remove debug error messages from Resource.cc |
| x11/other/fluxbox | `0003-fixes-bug-1138.patch` | Fix bug #1138: pointer comparison fix in fluxbox-remote |
| x11/other/fluxbox | `0080-fix-gettext-build.patch` | Add AM_GNU_GETTEXT_VERSION for gettext 0.24.1 compat |
| x11/util/xorg-launch-helper | `0001-automake-1.14.patch` | Add subdir-objects flag for automake 1.14 |
| x11/xserver/xorg-server | `1001-detect-radeon.patch` | Detect AMD GPUs as "radeon" instead of "ati" driver |
| tools/grub | `0001-build-fix-initialization-discards-const-qualifier-fr.patch` | Rudi Heitbaum — glibc-2.43 C23 const-qualifier build fix (bsearch/memchr/strchr etc.). **master only** — dev dropped it in `60ba085127` and both trees are on grub 2.14, so check whether master can drop it too |
| addons/addon-depends/rpi_ws281x | `0001-rename-version-to-VERSION-to-avoid-shadowing-cxx20.patch` | Rudi Heitbaum — rename CMake `version` file to avoid shadowing C++20 `<version>` |
| addons/addon-depends/system-tools-depends/hd-idle | `0001-makefile.patch` | Lukas Rusak — drop `-o root -g root` from install for non-root cross-build |
| addons/addon-depends/rpi-tools-depends/lg-gpio | `0001-PY_LGPIO-replace-removed-SWIG-Python-2-compatibility.patch` | Rudi Heitbaum — swig 4.5.0 removed the Python 2 compatibility macros from `pyhead.swg`, so the 21 `PyInt_*`/`PyString_*` calls in `PY_LGPIO/lgpio.i` no longer compile; to submit to joan2937/lg |

### Submitted upstream

Patches that have been submitted to the upstream project and are awaiting merge:

| Package | Patch | Notes |
|---------|-------|-------|
| network/avahi | `229.patch` | Nate Karstens — [avahi PR #229](https://github.com/avahi/avahi/pull/229) "reconfirm" feature (RFC 6762 §10.4); open upstream (v0.9.1 milestone). Carried for the dev 0.9-rc5 WIP bump |
| network/avahi | `309.patch` | Vladyslav Movchan — [avahi PR #309](https://github.com/avahi/avahi/pull/309) don't-conflict-with-self; **closed unmerged** upstream — carried for the 0.9-rc5 WIP |
| compress/7-zip | `0008-Fix-Globally-suppress-GCC-16-Warray-bounds-false-pos.patch` | YOKOTA Hiroshi — GCC 16 -Warray-bounds false positive; [sourceforge bug #2604](https://sourceforge.net/p/sevenzip/bugs/2604/) |
| debug/gdb | `0001-gdbserver-ctrl-c-handling.patch` | Khem Raj — gdbserver SIGINT fix; [GDB Bugzilla #18945](https://sourceware.org/bugzilla/show_bug.cgi?id=18945) |
| textproc/xmlstarlet | `0001-usage2c.awk-fix-wrong-basename-regexp.patch` | Matthieu Crapet — fix basename regexp; submitted to sourceforge |
| addons/addon-depends/comskip | `0001-drop-deprecated-ffmpeg8-ticks-per-frame.patch` | Greg Scaffidi — FFmpeg 8 deprecated ticks-per-frame; [PR #187](https://github.com/erikkaashoek/Comskip/pull/187) (open) |
| addons/addon-depends/comskip | `0002-fix-OutputFrame-declaration-for-gcc15.patch` | Rudi Heitbaum — gcc-15 fix; [PR #177](https://github.com/erikkaashoek/Comskip/pull/177) **merged 2025-04-18** — drop on a comskip release past V0.83 (V0.83 tag predates the merge) |
| addons/addon-depends/docker/tini | `0233-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #233](https://github.com/krallin/tini/pull/233) CMake 4.0 build fix; **merged to master** — drop when tini releases past 0.19.0 |
| addons/addon-depends/ffmpegx-depends/x265 | `0001-cmake-generate-asm-objects-from-a-single-target.patch` | Rudi Heitbaum — the asm objects are listed as sources of both x265-static and x265-shared, so the generating rule is written into each target and a parallel build can run two compilers writing the same object file; a link then reads a truncated object (`ld.gold: error: p2s-sve.S.o: file is empty`) and the aarch64 addon build fails intermittently. Drives the rules from one `x265-asm` target the consumers depend on. Sent to x265-devel@videolan.org; **dev only**, master carries no x265 patches. Drop on an x265 release past 4.2 that includes the fix |
| addons/addon-depends/network-tools-depends/lftp | `0001-link-readline-with-termcap.patch` | Lukas Rusak — link readline with termcap |
| addons/addon-depends/network-tools-depends/lftp | `0776-allow-build-with-OpenSSL-4.x.patch` | Rudi Heitbaum — [PR #776](https://github.com/lavv17/lftp/pull/776) OpenSSL 4.x build fix; **merged 2026-03** — drop on an lftp release past 4.9.3 |
| addons/addon-depends/network-tools-depends/nmap | `0001-allow-build-with-automake-1-17.patch` | Rudi Heitbaum — automake 1.17 build fix; **no upstream PR found** (submit to nmap-dev or confirm) |
| addons/addon-depends/network-tools-depends/rar2fs | `0002-fix-configure.patch` | Rudi Heitbaum — [PR #193](https://github.com/hasse69/rar2fs/pull/193) autotools configure fix; **merged 2024-07** — drop on a rar2fs release past 1.29.7 |
| addons/addon-depends/system-tools-depends/encfs | `0677-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #677](https://github.com/vgough/encfs/pull/677) CMake 4.0 build fix; **PR closed/rejected** (upstream dropped the C++ build) — carried locally, will not merge |
| addons/addon-depends/system-tools-depends/hid_mapper | `0001-crosscompile.patch` | Lukas Rusak — use ${CXX} instead of hardcoded g++ |
| addons/addon-depends/system-tools-depends/hid_mapper | `0002-Fix-key-code-reading.patch` | Diomidis Spinellis — include required header for fd_set |
| addons/addon-depends/system-tools-depends/hid_mapper | `0003-include-sys-time.patch` | Lukas Rusak — include sys/time.h |
| addons/addon-depends/system-tools-depends/screen | `0001-rename-pty-h-to-screen-pty-h.patch` | Rudi Heitbaum — rename pty.h to avoid glibc conflict |
| addons/addon-depends/system-tools-depends/screen | `0002-Include-pty.h-when-openpty-is-available-so-glibc-bui.patch` | Peter Dey — [Savannah bug #68134](https://savannah.gnu.org/bugs/?68134) include <pty.h> when openpty() available |
| addons/addon-depends/vdr-plugins/vdr-plugin-robotv | `0022-cmake-allow-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #22](https://github.com/pipelka/vdr-plugin-robotv/pull/22) CMake 4.0 build fix; **merged to master** — drop on a release past 0.15.0 |
| addons/addon-depends/vdr-plugins/vdr-plugin-wirbelscan | `0001-interface-channel-count.patch` | mglae — add missing extern TChannels declaration |
| addons/addon-depends/vdr-plugins/vdr-plugin-wirbelscancontrol | `0001-Makefile-allow-CC-and-CXX-to-be-overwritten.patch` | Rudi Heitbaum — allow CC/CXX override for cross-compile; **merged to master** — drop on a release past 0.0.3 |
| addons/service/proftpd | `0100-always-use-unsigned-long-long-for-offsets.patch` | cvh — cross-compile HAVE_LLU fix; upstream proftpd `llu` branch |
| multimedia/media-driver | `1919-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #1919](https://github.com/intel/media-driver/pull/1919) CMake 4.0 build fix |
| network/connman | `0004-TEST-wifi-Extend-auth-retry-mechanism-to-WPA3-SAE.patch` | Johannes Emerich — WPA3-SAE auth retry |
| network/connman | `0005-TEST-wifi-Limit-invalid-key-to-repeated-auth-failure.patch` | Johannes Emerich — WPA3 invalid-key handling |
| network/connman | `0006-TEST-wifi-Allow-retries-for-more-assoc-failure-cases.patch` | Johannes Emerich — WiFi assoc retry improvements |
| network/wsdd-native | `0001-read-the-unicast-socket-so-its-receive-queue-drains.patch` | Rudi Heitbaum — [PR #34](https://github.com/gershnik/wsdd-native/pull/34), fixing [issue #30](https://github.com/gershnik/wsdd-native/issues/30): `m_unicastSendSocket` is bound to the interface address on port 3702 but never read, so every unicast datagram sent to the host's WSD port queues forever and directed unicast requests go unanswered. Arms a read on it as well. **dev only**, verified on hardware; drop on a release past `2204c8ca` that carries the fix |
| sysutils/open-vm-tools | `0779-glib-stubs--avoid-GLib-g-free-macro-redefinition-erro.patch` | Khem Raj — [PR #779](https://github.com/vmware/open-vm-tools/pull/779) avoid g_free macro redefinition with glib 2.78+ |
| sysutils/open-vm-tools | `0783-fix-initialization-discards-const-qualifier-from-poi.patch` | Rudi Heitbaum — [PR #783](https://github.com/vmware/open-vm-tools/pull/783) fix glibc-2.43 const-qualifier |
| tools/bcm2835-utils | `0088-vclog--fix-max-realloc-compiler-error.patch` | Rudi Heitbaum — [PR #88](https://github.com/raspberrypi/utils/pull/88) fix alloc-size compiler error |
| wayland/wayland-protocols | `0001-build-add-Cflags-to-pkg-config-when-headers-are-inst.patch` | Rudi Heitbaum — add Cflags to pkg-config for wlroots 0.20+ |

### Intentionally local (le-specific)

Packages whose patches are 100% LibreELEC-specific and will not go upstream:

| Package | # Patches | Nature |
|---------|-----------|--------|
| sysutils/systemd | 5 | Path redirects (`/storage/.config`, `hwdb.bin → /run`), timer persistence, cursor config |
| sysutils/busybox | 6 | Halt behaviour, crond silence, dd fsync revert, passwd/shadow handling |
| network/bluez | 8 | Device quirks (Logitech, Sixaxis, QCA), obex policy, storage dir, gcc warning fixes in the carried QCA9377 hciattach vendor code |
| network/openssh | 3 | Custom `--with-keydir`, identity-file silence, source `/etc/environment` |
| network/connman | 3 | Route cleanup disable on startup, IPv6 off by default, link against ncurses |
| network/samba | 2 | Disable man page build (no-man, no-man-4.16) |
| audio/alsa-lib | 1 | Add `/run/asound.conf` as a config location |
| addons/service/tvheadend43 | 2 | DVB scan path for LE, libhdhomerun include path |
| rust/rust | 1 | LibreELEC target specifications (aarch64, armv7a, armv7ve, x86_64) |
| wayland/compositor/sway | 2 | Static IPC socket path, drop git version string |
| network/libshairplay | 1 | Read airport key from `/etc` |
| lang/Python3 | 12 | Disable pydoc/IDLE/tk/curses, optimised default, legacy pyc generation (the 13th patch in the tree is the dev-only OpenSSL 4 backport above) |
| devel/glibc (`widevine-arm/`) | 2 | ChromeOS `libwidevinecdm.so` ABI compatibility hacks |
| devel/glibc | 1 | Dev-only yacc/build workaround: drop `static` from `intl/plural.y` yylex/yyerror to match generated code (upstream keeps them static by design, not an upstream backport) (`glibc234-yyerror-match-posix-standard`) |
| addons/addon-depends/chrome-depends/unclutter | 1 | Modern-gcc build fixes (implicit-int, prototypes, missing includes); classic unclutter upstream dead (0001) |
| addons/addon-depends/docker/cli | 1 | LE addon storage path (`/storage/.kodi/addons`) |
| addons/addon-depends/dvb-tools-depends/dvb-apps | 1 | Remove av7110_loadkeys (unsupported hardware) |
| addons/addon-depends/flatpak-depends/appstream | 1 | Disable tests (cannot run in cross-compile) |
| addons/addon-depends/game-tools/linuxconsoletools | 1 | No force-feedback tools on HTPC appliance |
| addons/addon-depends/go | 1 | Add `/etc/ssl` as LE cert directory |
| addons/addon-depends/podman/netavark | 1 | No docs on appliance (`0001-no-docs.patch`); carried on master but skipped by `patch-scan.py`'s `podman/` exclusion |
| addons/addon-depends/libhdhomerun | 1 | Static library build for LE addon |
| addons/addon-depends/libmad | 1 | Static-only install (no shared library) |
| addons/addon-depends/multimedia-tools-depends/opencaster | 1 | Don't build dvbobjects (0002) |
| addons/addon-depends/network-tools-depends/depends/libpcap | 1 | No man pages on appliance |
| addons/addon-depends/network-tools-depends/rar2fs | 1 | No man pages on appliance (0001) |
| addons/addon-depends/qt5 | 1 | Sysroot-relative pkgconfig/libtool paths for cross-compile |
| addons/addon-depends/snapcast-depends/snapcast | 1 | Force avahi mDNS backend (`--mdns=avahi`) |
| addons/addon-depends/system-tools-depends/depends/libmtp | 1 | No docs/examples on appliance |
| addons/addon-depends/system-tools-depends/file | 1 | LE addon data path (`.kodi/addons`) |
| addons/addon-depends/system-tools-depends/lm_sensors | 1 | Force static linking for LE addon |
| addons/addon-depends/system-tools-depends/st | 1 | Scrollback keyboard shortcuts (0002) |
| addons/addon-depends/vdr-plugins/vdr-plugin-epgsearch | 1 | No docs in build (0002) |
| addons/addon-depends/vdr | 2 | Reduce channels.conf autosave delay, silence OSD-less log noise |
| addons/service/mariadb | 1 | Disable PAM plugin (unavailable in LE cross-compile) (0001) |
| addons/service/minidlna | 1 | Disable build-time editing of config files (0001) |
| addons/service/mpd | 1 | Static libopenmpt linking for LE addon |
| addons/service/net-snmp | 2 | `/storage/.kodi` config path, systemctl stop integration |
| addons/service/tigervnc | 1 | Disable tests (cannot run in cross-compile) |
| audio/fluidsynth | 1 | Force static libsndfile |
| audio/libsndfile | 1 | Static dep list in pkg-config (Libs.private cross-compile workaround) (0001) |
| audio/pulseaudio | 2 | Drop version-dirty string, remove UID file ownership check |
| databases/sqlite | 1 | Add MAP_POPULATE to mmap calls (pre-fault pages for appliance performance) |
| debug/libunwind | 1 | Static dep list in pkg-config (Libs.private cross-compile workaround) (0002) |
| debug/strace | 1 | Hardcode version in AC_INIT to avoid git-version-gen in LE build env (0001) |
| emulation/libretro-bsnes-hd | 1 | Disable OpenMP (not available in cross-compile toolchain) |
| emulation/libretro-bsnes | 1 | Disable OpenMP (not available in cross-compile toolchain) |
| graphics/giflib | 1 | No shared library install (appliance uses static only) |
| graphics/vulkan/glslang | 1 | Force static SPIRV-Tools build (LE static packaging requirement) |
| lang/gcc | 3 | Disable multilib i386, allow newer autoconf for LE build env, cross-compile host-path safety |
| linux-driver-addons/dvb/crazycat | 1 | Disable SAA7146 PCI DVB hardware (not supported on LE appliance) |
| linux-driver-addons/dvb/dvb-latest | 1 | Disable SAA7146 PCI DVB hardware (not supported on LE appliance) |
| multimedia/ffmpeg (libreelec/) | 1 | LE-specific libdav1d get_format and AV patches |
| multimedia/ffmpeg (rpi/) | 1 | Downstream RPi ffmpeg patch set imported wholesale (~24k lines); exempt from the naming and refresh rules |
| multimedia/libbluray | 1 | JVM headless=false and LE temp path (/storage/.kodi/...) |
| security/libgcrypt | 1 | Skip building tests during cross-compile (0002) |
| security/nss | 2 | Skip shlibsign (can't run in cross-compile), disable HOST_CFLAGS contamination (0002-0003) |
| sysutils/dosfstools | 1 | Silence backup boot sector diff in non-interactive mode (log spam) |
| sysutils/fuse | 1 | Don't run update-rc.d (LE uses different init system) (0002) |
| sysutils/libhid | 1 | Disable docs build on appliance (0002) |
| sysutils/lirc | 1 | Disable Python support (LE doesn't use lirc Python bindings) (0100) |
| sysutils/v4l-utils | 1 | Disable BPF protocols build (requires clang, not in LE cross-compile) (0001) |
| devel/autoconf | 1 | Exclude autoreconf.1 man page (man pages excluded from LE build)  |
| devel/binutils | 2 | Warn/skip host system dirs in cross-linker (0001), skip makeinfo for bfd docs (0002) |
| devel/flex | 1 | Remove doc/examples/po/tests from build (0002) |
| devel/gettext | 2 | Non-interactive gettextize (0001), no docs/examples (0002) |
| devel/ncurses | 1 | Trim recent xterm terminfo features (LE terminal compatibility) (0001) |
| tools/mtools | 1 | Remove floppyd, man pages, info from install (not needed on appliance) |
| tools/plymouth-lite | 1 | Static link with libpng/zlib/math (appliance packaging) |
| x11/lib/libX11 | 1 | Disable NLS tests (cannot run in cross-compile) |
| x11/other/fluxbox | 1 | Don't build fbrun run dialog (not needed on LE appliance) (0004) |
| x11/util/xorg-launch-helper | 2 | Skip libsystemd-daemon check (0002), increase X startup timeout to 30s (0003) |
| x11/xserver/xorg-server | 1 | Fedora downstream extra display-modes list, never upstreamed (1002) |

### Backports (cherry-picked from upstream)

Patches already merged in the upstream project — drop on the next version bump past the fix:

| Package | Patch | Upstream source |
|---------|-------|----------------|
| network/avahi | `0001-dbus--Use-non-deprecated-installation-path.patch` | Jan Tojnar — avahi upstream: install dbus policy to `${datadir}/dbus-1/system.d` (dbus 1.14 deprecation). **master only** — the fix is in the dev 0.9-rc5 base, so dev carries only `229`/`309` |
| network/samba | `0200-4.11-fix-ASN1-bso14164.patch` | Uri Simchoni, Heimdal embedded build fix |
| devel/flex | `0262-AC-USE-SYSTEM-EXTENSIONS-in-configure-ac.patch` | [upstream PR #262](https://github.com/westes/flex/pull/262) |
| devel/flex | `0674-Match--malloc--signature-to-its-use.patch` | [upstream PR #674](https://github.com/westes/flex/pull/674) |
| network/libnfs | `0514-socket-use-void-cast-to-allow-compile-for-arm32.patch` | [upstream PR #514](https://github.com/sahlberg/libnfs/pull/514) |
| network/libnfs | `0576-Do-not-edit-const-and-use-const-qualifier-from-point.patch` | [upstream PR #576](https://github.com/sahlberg/libnfs/pull/576) |
| tools/syslinux | `0001-fix-build-with-glibc-2.28.patch` | Mike Frysinger (Gentoo) |
| addons/addon-depends/rsyslog-depends/snappy | `0086-add-pkg-config-file.patch` | Sebastien Lavoie — [upstream PR #86](https://github.com/google/snappy/pull/86) add CMake pkg-config file |
| addons/addon-depends/steamlink-depends/krb5 | `0001-Fix-strchr-conformance-to-C23.patch` | Alexander Bokovoy (Red Hat) — [upstream ticket #9191](https://bugs.mit.edu/show_bug.cgi?id=9191) |
| addons/addon-depends/steamlink-depends/krb5 | `1485-autoconf-ac-init.patch` | Samuel Cabrero (SUSE) — [upstream ticket #9202](https://bugs.mit.edu/show_bug.cgi?id=9202) autoconf 2.73 compat |
| addons/addon-depends/system-tools-depends/encfs | `0863-build-with-cmake-4.0.0.patch` | Benjamin A. Beasley (Fedora) — CMake 4.0 support |
| addons/service/tigervnc | `1366-raise-cmake-requirement-to-3.10.patch` | Pierre Ossman (TigerVNC maintainer) — [upstream PR #1366](https://github.com/TigerVNC/tigervnc/pull/1366) |
| audio/libcdio | `0001-remove-lfs-shms.patch` | Alfred Wingate (Gentoo) — [Savannah bug #65751](https://savannah.gnu.org/bugs/?65751) rely on `_FILE_OFFSET_BITS=64` |
| network/nftables | `0001-fix-configure-with-non-bash-shell.patch` | Jan Palus / Pablo Neira Ayuso — fix configure with non-bash CONFIG_SHELL |
| security/libxcrypt | `0001-fix-Werror-discarded-qualifiers.patch` | Stanislav Zidek (Red Hat) — remove const casts on strchr return value (GCC strict const) |
| textproc/itstool | `0001-Fix-insufficiently-quoted-regular-expressions.patch` | Nils Philippsen — fix Python 3.12 regex quoting warnings |
| textproc/itstool | `0057-use-lxml-not-libxml2.patch` | Nick Wellnhofer — switch from libxml2 Python bindings to lxml |
| addons/addon-depends/network-tools-depends/nmap | `0002-Fix-build-with-OpenSSL-4-x.patch` | Daniel Miller — OpenSSL 4.x build fix ([nmap issue #3375](https://github.com/nmap/nmap/issues/3375)); not in the 7.99 release |
| devel/crossguid | `0001-pr67-include-missing-cstdint.patch` | Khem Raj (OE) — [upstream PR #67](https://github.com/graeme-hill/crossguid/pull/67) add <cstdint> for GCC 13 |
| devel/gcem | `0054-fix-cmake-minimum~required.patch` | BartolomeyKant — update CMake minimum to 3.10..3.31 |
| devel/glibc | `0001-Makerules-install-the-ABI-lib-names-header-from-the-.patch` | Rudi Heitbaum — [BZ 34439](https://sourceware.org/bugzilla/show_bug.cgi?id=34439); **merged** as [`82c0a96b8e`](https://sourceware.org/git/?p=glibc.git;a=commit;h=82c0a96b8e63005a49ba52ddb21993811030613f) on master and cherry-picked to `release/2.44/master` as [`45b8a13c48`](https://sourceware.org/git/?p=glibc.git;a=commit;h=45b8a13c48da92bc5dd6fe102011391dd6847862). Drop on 2.44.1 or 2.45. Upstream's version adds an explanatory comment above the `ifndef subdir`; ours is otherwise identical |
| devel/gmp | `0001-acinclude.m4-fix-std-c23-build-failure.patch` | upstream GMP hg [18477:8e7bb4ae7a18](https://gmplib.org/repo/gmp/rev/8e7bb4ae7a18) — fix -std=c23 configure test failure |
| devel/heimdal | `1229-cf-largefile.m4-Fix-build-with-autoconf-2.72.patch` | Bernd Kuhls (Buildroot) — fix for [upstream heimdal issue #1201](https://github.com/heimdal/heimdal/issues/1201) |
| devel/libevent | `0001-build-with-cmake-4.0.0.patch` | Azat Khuzhin (libevent author) — require CMake 3.1.2 for OpenSSL detection |
| devel/libevent | `0002-build-with-cmake-4.0.0.patch` | Ingo Bauersachs — make dependency paths relocatable |
| devel/libevent | `0003-build-with-cmake-4.0.0.patch` | Cœur — fix CMake deprecation warning (3.4→3.5) |
| devel/libevent | `0004-build-with-cmake-4.0.0.patch` | Hennadii Stepanov — update CMake minimum to 3.10 |
| devel/make | `0001-fix-large-command-line-on-POSIX-systems.patch` | Mike Crowe — fix long command lines on POSIX; [SV 45763](https://savannah.gnu.org/bugs/?45763) |
| lang/Python3 | `Python3-146403-Add-support-for-OpenSSL-4.0.0.patch` | Victor Stinner — [gh-146207 / GH-146217](https://github.com/python/cpython/pull/146217) add support for OpenSSL 4.0.0 (drops `SSLv3_method`/`TLSv1*_method`); **dev only**, needed by dev's OpenSSL 4.0.1. Filename says 146403 but the commit is gh-146207 — rename to the `####-subject.patch` convention |
| security/nss | `nss-10-Bug-1801182-Allow-overriding-OS_ARCH-OS_TEST-and-OS_.patch` | Giulio Benetti (Buildroot) — [Mozilla bug 1801182](https://bugzilla.mozilla.org/show_bug.cgi?id=1801182) allow overriding `OS_ARCH`/`OS_TEST`/`OS_RELEASE` with make ≥ 4.3.91; **dev only**, needs renaming to the convention |
| databases/mariadb-connector-c | `0001-fix-build-error-on-32-bit-systems.patch` | Chad Wagner — cast size_t to ulonglong on 32-bit platforms |
| debug/libunwind | `0001-fix-multiple-definition.patch` | [upstream commit 0e74e583](https://github.com/libunwind/libunwind/commit/0e74e583) — add arm_search_unwind_table macro |
| debug/vadumpcaps | `0005-handle-drivers-that-dont-return-any-drm-format-modifi.patch` | Philip Langdale — null check for DRM format modifiers; [upstream issue #4](https://github.com/challlenge/vadumpcaps/issues/4) |

### Dev-only WIP — carried on dev, not on master, not yet classified

These packages carry patches on `dev` only and have no row in the tables above. `tools/patch-scan.py` will not flag them:
it reports untracked patches for the tracked ref (master) only. Classify or drop as each experiment settles.

| Package | # | Nature |
|---------|---|--------|
| sysutils/udisks | 7 | Build-option toggles (explicit libsystemd-login disable, optional polkit, building without libblockdev mdraid/crypto) and the authorization-function split, plus `0001-mm.patch`/`0002-c.patch` scratch patches that need real names or removal |
| linux-drivers/gasket-driver | 3 | Kernel 6.12/6.13 compat (`MODULE_IMPORT_NS()` string literal) and a flexible Makefile |
| graphics/nvidia | 2 | linux 7.2 build fixes (`drm-atomic-state-to-commit`, `strncpy-removed`) — see the nvidia section in CLAUDE.md |
| multimedia/rtmpdump | 2 | glibc-2.43 C23 const-qualifier fixes (`9446a8417c`) |
| addons/addon-depends/mp4v2 | 2 | 5.0.1-to-master diff plus a CMakeLists change to build mp4v2 and mp4info — part of the "move mp4v2 to 2.x" roadmap item |
| tools/u-boot (`rockchip/`) | 2 | mkimage RK356X support (two upstream commit hashes as filenames) |
| compress/lz4 | 1 | [PR #1479](https://github.com/lz4/lz4/pull/1479) add back the `lz4c` target, default OFF |
| addons/addon-depends/system-tools-depends/dislocker | 1 | cmake: allow explicitly disabling the Ruby bindings |
| addons/service/librespot | 1 | openssl crate bump to v0.10.78 (upstream PR 1707) |
| network/iwd | 1 | `debug.patch` — WIP debug toggle |
| tools/fwupd | 1 | Build with static libarchive |
| x11/proto/xorgproto | 1 | pkgconfig fix |
| supervisedthinking/…/makemkv | 1 | Build warning fix in the third-party makemkv addon tree |

### Project patches — `projects/`, outside patch-scan's reach

`tools/patch-scan.py` only walks `packages/`, so nothing under `projects/` is
reconciled by it or was tracked here at all. The Coral Dev Board set is the one
body of work large enough to need rows. It is **dev only** — 20 patches under
`projects/NXP/devices/iMX8/patches/linux/`, all against linux 7.2-rc5, applying
with no fuzz. Full working notes are in
`NXP.md`; this table is the submission state.

| Patch | Status | Notes |
|-------|--------|-------|
| `0001` `PCI: imx6: Avoid dereferencing a NULL clock name` | submitted | sent standalone 2026-08-02, `Acked-by: Richard Zhu` (NXP) 2026-08-03. Carries `Fixes: d8574ce57d76` and `Cc: stable`, so it should not wait for the merge window. Awaiting a PCI maintainer |
| `0002` `dt-bindings: pci: fsl,imx6q-pcie: Add extref clock` | submitted | series 1/3. **Awaiting a direction from Frank Li** - see `0003` |
| `0003` `PCI: imx6: Select the PCIe REF_CLK source on i.MX8MQ` | submitted | series 2/3. **Needs a v2 and the shape is not ours to choose.** Frank Li agrees `enable_ext_refclk` is the right direction for i.MX95 alignment but flagged a real backward-compatibility break: on i.MX8MQ the absence of `"extref"` is ambiguous, meaning both "existing devicetree, reference on the pad" and "this board drives REF_CLK from the internal PLL", so clearing `REF_USE_PAD` regresses any devicetree without the new clock. `0004` covers all five in-tree boards, leaving old-DTB-with-new-kernel and out-of-tree devicetrees exposed. A new devicetree property was tried in the NXP tree and rejected, so we asked Frank how he wants the internal-PLL case described rather than proposing a shape (replied 2026-08-08) |
| `0004` `arm64: dts: imx8mq: Declare the PCIe extref clock` | submitted | series 3/3, 5 boards. May become unnecessary depending on `0003`'s v2 |
| `0005` `ASoC: rt5645: Make the Kconfig symbol user selectable` | **in mainline, patch dropped** | [`588852647b81`](https://git.kernel.org/torvalds/c/588852647b81), landed 2026-08-08 via `broonie/sound`. Verified: `SND_SOC_RT5645` now reads `tristate "Realtek RT5645/RT5650 Codec"` in Linus's tree. Dropped from the tree on `linux-7.2`, whose kernel is 7.2-rc7 and so carries it, which also satisfies `0010`'s dependency from the base. It cannot be dropped on a tree still at rc5 or rc6: `SND_SOC_RT5645` goes back to being promptless, `olddefconfig` then silently drops `CONFIG_SND_SOC_RT5645=y` and the analog card disappears with no error. The hash is now a mainline one, so it may be cited in a commit message |
| `0006` phanbell keep the GPU rail on (buck3 always-on) | submitted | v2 posted to the imx list 2026-08-08 as part of the 5-patch "Google Coral Dev Board enablement" series; `buck3` is already in mainline phanbell |
| `0007` phanbell do not hardcode a cooling state | submitted | v2 posted to the imx list 2026-08-08 as part of the 5-patch "Google Coral Dev Board enablement" series; `map1` is in mainline phanbell, `THERMAL_NO_LIMIT` comes via `imx8mq.dtsi` |
| `0008` phanbell enable i2c2 and i2c3 | submitted | v2 posted to the imx list 2026-08-08 as part of the 5-patch "Google Coral Dev Board enablement" series; depends on nothing |
| `0009` phanbell mux the 32 kHz reference clock pad | submitted | v2 posted to the imx list 2026-08-08 as part of the 5-patch "Google Coral Dev Board enablement" series; the one hog entry with a real signal behind it |
| `0010` phanbell rt5645 analog audio | submitted | v2 posted to the imx list 2026-08-08 as part of the 5-patch "Google Coral Dev Board enablement" series; needs `0005` and `0008` (appends into its `&i2c3`). v2 adds `avdd-supply`/`cpvdd-supply` with a fixed `reg_audio_1v8`, and the `"IN1P", "Headphone Mic"` route, both from Frank Li's review of v1; `CHECK_DTBS` is clean. The cpu dai deliberately carries no `clocks` - naming one bypasses `fsl_sai_set_mclk_rate()` and breaks 44.1 kHz. Moved ahead of the pcie patches in `30b2660e3f` so the submittable set is a prefix |
| `0011` phanbell enable pcie0 and pcie1 | pending | needs `0003` - pristine `imx8mq_pcie_init_phy()` sets `REF_USE_PAD` unconditionally, and pcie0 takes REF_CLK from the internal PLL, so it needs that made conditional. `0002` documents the `"extref"` name pcie1 uses. Carries the VPH rail and `reg_wlan` |
| `0012` phanbell QCA6174 Bluetooth on uart2 | pending | needs `0011` for `reg_wlan` - the QCA6174 is a combo part and WL_REG_ON (GPIO3_IO11) powers the Bluetooth side as much as the wifi radio |
| `0014` `ASoC: rt5645: Perform the initial jack detect at probe` | submitted | posted to ASoC 2026-08-06. An upstream bug rather than a board quirk: any `simple-audio-card` user of rt5645/rt5650 with `hp-detect-gpios` and `jd-mode = 0` is silent until the jack is physically replugged, because nothing calls `rt5645_set_jack_detect()` and so nothing force enables the `LDO2`/`Mic Det Power` supplies `HP amp` depends on. Sent to ASoC alongside `0005`. **No `Fixes:` and no `Cc: stable`**, and the grep backs that up: no in-tree DTS references `realtek,rt5645` at all, the three `rt5650` boards (mt8173-elm, mt8186-corsola-squirtle/chinchou) all set `realtek,jd-mode = <2>`, no DT anywhere uses `hp-detect-gpios`, and all seven callers of `rt5645_set_jack_detect()` are machine drivers. Both conditions the patch tests are unmet upstream, so it cannot affect a released kernel and is a no-op for every current user |
| `0013` phanbell 40-pin header I2S card on sai1 | pending | weakest of the set - a dummy card for an expansion header with `linux,spdif-dit` standing in for a codec that is not there. Consider keeping this one local rather than posting it |
| `0021`-`0028` Cadence MHDP8501 HDMI/DP (Laurentiu Palcu, `[PATCH v23 0/8]`) | imported | 8 patches, unmerged upstream but in active review. Applies clean to 7.2-rc6, so two of the three 7.2 fixes the v20 import needed are gone - the `drm_atomic_commit` rename and the `devm_drm_bridge_alloc` conversion. The third is **still needed**: `cdns_mhdp8501_irq_thread()` queues its debounce work with `mod_delayed_work(system_wq, ...)` and 7.2 marks `system_wq` `__WQ_DEPRECATED`, so the hotplug warning returns on the first HDMI plug event. One line, `system_percpu_wq`, and worth sending to Laurentiu. Needs `CONFIG_DRM_DISPLAY_CONNECTOR` |
| `0029` imx8mq-evk DCSS + HDMI (Lucas Stach) | imported | downstream, needs the MHDP series |
| `0030` imx8mq-pico-pi DCSS + HDMI (Lukas Rusak) | imported | downstream, needs the MHDP series |
| `0031` imx8mq-phanbell DCSS + HDMI | pending | needs the MHDP series; **working** on hardware |
| `0032` `drm: bridge: cadence: add HDMI audio support to MHDP8501` | pending | needs the MHDP series. v23 still has no audio, so this remains a real gap and is now worth posting as a follow-up to a **live** series rather than a dead one. Reworked for v23: `bridge_to_mhdp()` not `bridge->driver_private`, which v23 leaves NULL since it allocates the bridge with `devm_drm_bridge_alloc()` |
| `0033` phanbell HDMI audio card on sai4 | pending | needs `0032` and `0031`; **working** - 44.1 kHz plays and Kodi playback is fine |

**Where this set lives.** The numbering in these tables is the `linux-7.2`
branch, which is the current state: kernel 7.2-rc7, `0005` dropped because the
base carries it, the MHDP series at v23 as `0021`-`0028`, and
`CONFIG_DRM_DISPLAY_CONNECTOR=y`. `dev` still has the older shape - kernel
7.2-rc5, `0005` present and the v20 MHDP import as `0021`-`0026` - so read these
tables against `linux-7.2`, not against `dev`.

**Submit only a prefix.** Every patch's diff context is generated against the
state its predecessors leave, so a prefix always applies and an arbitrary subset
may not — `30b2660e3f` exists because the audio patch had been built on top of
the pcie ones and applied with fuzz without them. The order now matches the plan:

| patches | when |
|---|---|
| `0006`–`0010` | now; the kernel carries `588852647b81`, so the Kconfig half comes from the base and `0010` needs only `0008` |
| `0011`–`0012` | when `0003` lands |
| `0013` | keep local; last so it never blocks a prefix |
| `0021`–`0033` | blocked on the MHDP series |

Verified with `git apply`, which refuses fuzz and so is the real test for
`git am`: `0001`–`0014` apply in order, `0006`–`0010` apply to a pristine
`imx8mq-phanbell.dts`, `0011`–`0012` apply on top, and `0013` on top of that.

Three of these dependencies are functional rather than textual, and reading patch
context does not find that class at all. `0012` applies to a tree without `0011`
and then fails to download firmware, because nothing has enabled WL_REG_ON.
`0010` applied without `0005` would describe a codec whose driver cannot be
enabled, since `SND_SOC_RT5645` was promptless upstream until `588852647b81`.
`0011`'s dependency on `0003` is the same shape: it is about what `REF_USE_PAD`
defaults to, so nothing in the diff hints at it.

`0008` through `0013` were rebuilt for upstream in `3d25559614`. The old `0008`
bundled five unrelated changes; what came out of it, and what was dropped as
downstream-only or certain to be rejected, is recorded in that commit message.
The pmic `IRQ_TYPE_LEVEL_LOW` → `GPIO_ACTIVE_LOW` retune noted here previously is
one of the things dropped, so that question is settled.

**Booted clean on 7.2-rc6, build 20260804161745**, which exercises both things the
rework changed rather than merely rearranged:

- WL_REG_ON went from a gpio-hog to a `regulator-fixed` consumed as pcie0's
  `vpcie-supply`. ath10k enumerates the QCA6174 and loads firmware, and
  `QCA setup on UART is completed`, so both halves of the combo part are
  powered. The intended ordering change is visible: pcie0's host bridge appears
  at 0.883 s where it used to appear at 0.746 s, i.e. the probe now defers on
  the regulator instead of racing the hog.
- the pmic interrupt went back to `IRQ_TYPE_LEVEL_LOW`. `bd718xx-pwrkey`
  registers and the boot proceeds with no interrupt storm, which was the one way
  the vendor's edge-triggered value could have been deliberate.

Audio on the three cards is complete and verified as of 2026-08-06, which took
four commits beyond the enablement patches - `b07e398f62` (the mixer path is
muted at reset), `1a5c9410ec`/`0014` (nothing performs the initial jack detect),
`869864bf5a` (neither audio PLL family was declared) and `1896dce677` (the SAI
was never marked as the system clock provider, so the mclk rate was never set at
all). All three cards now play 44.1 kHz natively and 48 kHz. Working notes in
`NXP.md`.

Dropping `ecspi1` and ten of the eleven hogged pins broke nothing, and `hoggrp`
still resolves with its single remaining pin.

### Needs triage

Patches in these packages have not yet been classified. Each patch should be assigned one of the status codes above:

 *(all packages triaged)*

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

Run `rename_plan.py` (repo root) to check conformance. After the 2026-08-01 dev cleanup it proposes **24 renames**, all in dev-only or WIP packages (nvidia's two linux-7.2 patches, comskip `arg3`, glibc's yacc workaround, Python3's OpenSSL 4 backport, nss `nss-10-…`, avahi `229`/`309`, mp4v2, dislocker, librespot, lz4, iwd, gasket-driver, rtmpdump, fwupd, u-boot rockchip, xorgproto, makemkv):

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
