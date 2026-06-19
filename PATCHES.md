## Patch Tracking

Every patch carried in `master` must be classified. The goal is to avoid accumulating patches: either submit fixes upstream or explicitly declare them intentionally local.

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
| devel/libbpf | `0001-fix-crosscompile-and-sysroot.patch` | Cross-compile sysroot fix |
| v4l-utils | `0999-pending-t2-descriptor.patch` | ETSI EN 300 468 T2 delivery-system descriptor freq fix |
| addons/addon-depends/argtable2 | `0001-fix-gcc-14-build.patch` | gcc-14 build fix |
| addons/addon-depends/chrome-depends/gtk3 | `0001-disable-to-pixdata-build.patch` | Disable to_pixdata build step |
| addons/addon-depends/chrome-depends/unclutter | `0001-fix-gcc-14-1-build.patch` | gcc-14 build fix |
| addons/addon-depends/chrome-depends/unclutter | `0002-fix-gcc-15-1-build.patch` | gcc-15 build fix |
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
| addons/addon-depends/vdr-plugins/vdr-plugin-dvbapi | `0001-crosscompiling.patch` | Build FFdecsa.o target not all in cross-compile |
| addons/addon-depends/vdr-plugins/vdr-plugin-epgsearch | `0001-don-t-build-unused-plugins.patch` | Skip unused plugin binaries |
| addons/addon-depends/vdr-plugins/vdr-plugin-restfulapi | `0001-fix-static-lib-order.patch` | Static library link order, add -lssl |
| addons/addon-depends/vdr-plugins/vdr-plugin-streamdev | `0001-support-locale-i18n.patch` | Add install-i18n to make targets |
| addons/addon-depends/vdr-plugins/vdr-plugin-xmltv2vdr | `0001-add-required-include-for-vdr-plugin-xmltv2vdr-0.2.2.patch` | Missing VDR include path for 0.2.2 |
| addons/service/boblightd | `0001-add-missing-getopt-includes.patch` | Missing unistd.h for getopt |
| addons/service/hyperion | `0001-fix-build-with-python-313.patch` | Python 3.13 build fix |
| addons/service/hyperion | `0002-build-with-cmake-4.0.0.patch` | CMake 4.0 build fix |
| addons/service/hyperion | `0003-fix-protobuf-cmake.patch` | Fix Protobuf CMake variable case |
| addons/service/lcdd | `0001-add-dm140-vfd-support.patch` | Add DM140 VFD driver support |
| addons/service/mariadb | `0002--fix-gcc14-build.patch` | gcc-14 build fix |
| addons/service/minidlna | `0002-fix-channel-layout-api-for-ffmpeg7.patch` | FFmpeg 7 channel layout API change |
| addons/service/oscam | `0001-link-with-ludev.patch` | Link against libudev |
| addons/service/oscam | `0002-pcsc-pthread.patch` | Link pcsclite with pthread |
| audio/ldacBT | `0001-build-with-cmake-4.0.0.patch` | CMake 4.0 build fix |
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
| graphics/libprojectM | `0001-add-enable-gl-switch.patch` | Add --enable-gl configure switch to allow GL-less builds |
| graphics/libprojectM | `0002-Allow-to-build-without-X11-on-Linux-and-BSD.-Added-fl.patch` | Allow building SOIL2 without X11 via SOIL_EGL/SOIL_NO_X11 flags |
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
| devel/glibc | `0002-fix-dns-with-broken-routers.patch` | Fix AI_ADDRCONFIG with broken routers (link-local IPv6 detection) |
| devel/intltool | `0001-fix-regex-expressions.patch` | Fix Perl regex escaping (${ in character classes) in intltool-update.in |
| devel/libbpf | `0001-fix-crosscompile-and-sysroot.patch` | Fix sysroot-relative prefix in .pc and add -lz to Libs |
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

### Submitted upstream

Patches that have been submitted to the upstream project and are awaiting merge:

| Package | Patch | Notes |
|---------|-------|-------|
| network/cifs-utils | `0001-fix-const-correctness-in-parse-options.patch` | Rudi Heitbaum — parse_options() const on data parameter was wrong; submitted to linux-cifs@vger.kernel.org |
| compress/7-zip | `0008-Fix-Globally-suppress-GCC-16-Warray-bounds-false-pos.patch` | YOKOTA Hiroshi — GCC 16 -Warray-bounds false positive; [sourceforge bug #2604](https://sourceforge.net/p/sevenzip/bugs/2604/) |
| debug/gdb | `0001-gdbserver-ctrl-c-handling.patch` | Khem Raj — gdbserver SIGINT fix; [GDB Bugzilla #18945](https://sourceware.org/bugzilla/show_bug.cgi?id=18945) |
| textproc/xmlstarlet | `0001-usage2c.awk-fix-wrong-basename-regexp.patch` | Matthieu Crapet — fix basename regexp; submitted to sourceforge |
| addons/addon-depends/comskip | `0001-drop-deprecated-ffmpeg8-ticks-per-frame.patch` | Greg Scaffidi — FFmpeg 8 deprecated ticks-per-frame |
| addons/addon-depends/comskip | `0002-fix-OutputFrame-declaration-for-gcc15.patch` | Rudi Heitbaum — gcc-15 OutputFrame declaration fix |
| addons/addon-depends/docker/tini | `0233-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #233](https://github.com/krallin/tini/pull/233) CMake 4.0 build fix |
| addons/addon-depends/network-tools-depends/lftp | `0001-link-readline-with-termcap.patch` | Lukas Rusak — link readline with termcap |
| addons/addon-depends/network-tools-depends/lftp | `0776-allow-build-with-OpenSSL-4.x.patch` | Rudi Heitbaum — [PR #776](https://github.com/lavv17/lftp/pull/776) OpenSSL 4.x build fix |
| addons/addon-depends/network-tools-depends/nmap | `0001-allow-build-with-automake-1-17.patch` | Rudi Heitbaum — automake 1.17 build fix |
| addons/addon-depends/network-tools-depends/rar2fs | `0002-fix-configure.patch` | Rudi Heitbaum — autotools configure fix |
| addons/addon-depends/system-tools-depends/encfs | `0677-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #677](https://github.com/vgough/encfs/pull/677) CMake 4.0 build fix |
| addons/addon-depends/system-tools-depends/hid_mapper | `0001-crosscompile.patch` | Lukas Rusak — use ${CXX} instead of hardcoded g++ |
| addons/addon-depends/system-tools-depends/hid_mapper | `0002-Fix-key-code-reading.patch` | Diomidis Spinellis — include required header for fd_set |
| addons/addon-depends/system-tools-depends/hid_mapper | `0003-include-sys-time.patch` | Lukas Rusak — include sys/time.h |
| addons/addon-depends/system-tools-depends/screen | `0001-rename-pty-h-to-screen-pty-h.patch` | Rudi Heitbaum — rename pty.h to avoid glibc conflict |
| addons/addon-depends/system-tools-depends/screen | `0002-Include-pty.h-when-openpty-is-available-so-glibc-bui.patch` | Peter Dey — [Savannah bug #68134](https://savannah.gnu.org/bugs/?68134) include <pty.h> when openpty() available |
| addons/addon-depends/vdr-plugins/vdr-plugin-robotv | `0022-cmake-allow-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #22](https://github.com/pipelka/vdr-plugin-robotv/pull/22) CMake 4.0 build fix |
| addons/addon-depends/vdr-plugins/vdr-plugin-wirbelscan | `0001-interface-channel-count.patch` | mglae — add missing extern TChannels declaration |
| addons/addon-depends/vdr-plugins/vdr-plugin-wirbelscancontrol | `0001-Makefile-allow-CC-and-CXX-to-be-overwritten.patch` | Rudi Heitbaum — allow CC/CXX override for cross-compile |
| addons/service/proftpd | `0100-always-use-unsigned-long-long-for-offsets.patch` | cvh — cross-compile HAVE_LLU fix; upstream proftpd `llu` branch |
| devel/json-c | `0888-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #888](https://github.com/json-c/json-c/pull/888) CMake 4.0 build fix |
| multimedia/media-driver | `1919-build-with-cmake-4.0.0.patch` | Rudi Heitbaum — [PR #1919](https://github.com/intel/media-driver/pull/1919) CMake 4.0 build fix |
| multimedia/media-driver | `1974-suppress-dangling-pointer-warning-in-mhw-state-heap-g.patch` | Rudi Heitbaum — [PR #1974](https://github.com/intel/media-driver/pull/1974) suppress GCC -Wdangling-pointer |
| network/connman | `0004-TEST-wifi-Extend-auth-retry-mechanism-to-WPA3-SAE.patch` | Johannes Emerich — WPA3-SAE auth retry |
| network/connman | `0005-TEST-wifi-Limit-invalid-key-to-repeated-auth-failure.patch` | Johannes Emerich — WPA3 invalid-key handling |
| network/connman | `0006-TEST-wifi-Allow-retries-for-more-assoc-failure-cases.patch` | Johannes Emerich — WiFi assoc retry improvements |
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
| network/bluez | 7 | Device quirks (Logitech, Sixaxis, QCA), obex policy, storage dir |
| network/openssh | 3 | Custom `--with-keydir`, identity-file silence, source `/etc/environment` |
| network/connman | 3 | Route cleanup disable on startup, IPv6 off by default, link against ncurses |
| audio/alsa-lib | 1 | Add `/run/asound.conf` as a config location |
| addons/service/tvheadend43 | 2 | DVB scan path for LE, libhdhomerun include path |
| rust/rust | 1 | LibreELEC target specifications (aarch64, armv7a, armv7ve, x86_64) |
| wayland/compositor/sway | 2 | Static IPC socket path, drop git version string |
| network/libshairplay | 1 | Read airport key from `/etc` |
| lang/Python3 | 12 | Disable pydoc/IDLE/tk/curses, optimised default, legacy pyc generation |
| devel/glibc (`widevine-arm/`) | 2 | ChromeOS `libwidevinecdm.so` ABI compatibility hacks |
| addons/addon-depends/docker/cli | 1 | LE addon storage path (`/storage/.kodi/addons`) |
| addons/addon-depends/dvb-tools-depends/dvb-apps | 1 | Remove av7110_loadkeys (unsupported hardware) |
| addons/addon-depends/flatpak-depends/appstream | 1 | Disable tests (cannot run in cross-compile) |
| addons/addon-depends/game-tools/linuxconsoletools | 1 | No force-feedback tools on HTPC appliance |
| addons/addon-depends/go | 1 | Add `/etc/ssl` as LE cert directory |
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
| addons/addon-depends/vdr-plugins/vdr-plugin-restfulapi | 1 | LE `/storage` webapp path (0002) |
| addons/addon-depends/vdr | 2 | Reduce channels.conf autosave delay, silence OSD-less log noise |
| addons/service/mariadb | 1 | Disable PAM plugin (unavailable in LE cross-compile) (0001) |
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
| devel/fakeroot | 1 | Disable docs and tests subdirs (not needed in LE build) |
| devel/flex | 1 | Remove doc/examples/po/tests from build (0002) |
| devel/gettext | 2 | Non-interactive gettextize (0001), no docs/examples (0002) |
| devel/ncurses | 1 | Trim recent xterm terminfo features (LE terminal compatibility) (0001) |
| tools/mtools | 1 | Remove floppyd, man pages, info from install (not needed on appliance) |
| tools/plymouth-lite | 1 | Static link with libpng/zlib/math (appliance packaging) |
| x11/lib/libX11 | 1 | Disable NLS tests (cannot run in cross-compile) |
| x11/other/fluxbox | 1 | Don't build fbrun run dialog (not needed on LE appliance) (0004) |
| x11/util/xorg-launch-helper | 2 | Skip libsystemd-daemon check (0002), increase X startup timeout to 30s (0003) |

### Backports (cherry-picked from upstream)

Patches already merged in the upstream project — drop on the next version bump past the fix:

| Package | Patch | Upstream source |
|---------|-------|----------------|
| network/avahi | `0001-dbus--Use-non-deprecated-installation-path.patch` | Jan Tojnar — use non-deprecated dbus `system.d` installation path (avahi upstream) |
| multimedia/intel-vaapi-driver | `0001-2.4.1-Handle-odd-resolution.patch` | Haihao Xiang (Intel), issue #516 |
| multimedia/intel-vaapi-driver | `0549-meson-warning-fixups.patch` | Eli Schwartz, Meson deprecation fix |
| graphics/tiff | `0001-cmake--Replace-CMath...` | Roger Leigh, CMake CMath export fix |
| devel/glibc | `0001-Linux--Only-define-OPEN-TREE-...` | Florian Weimer (Red Hat) |
| devel/glibc | `glibc234-yyerror-match-posix-standard.patch` | POSIX yyerror conformance |
| network/samba | `0200-4.11-fix-ASN1-bso14164.patch` | Uri Simchoni, Heimdal embedded build fix |
| devel/shared-mime-info | `0219-fix-build-with-libxml2-2-12-0.patch` | [upstream MR #219](https://gitlab.freedesktop.org/xdg/shared-mime-info/-/merge_requests/219) |
| devel/flex | `0262-AC_USE-SYSTEM-EXTENSIONS-in-configure-ac.patch` | [upstream PR #262](https://github.com/westes/flex/pull/262) |
| devel/flex | `0674-Match--malloc--signature-to-its-use.patch` | [upstream PR #674](https://github.com/westes/flex/pull/674) |
| network/libnfs | `0514-socket-use-void-cast-to-allow-compile-for-arm32.patch` | [upstream PR #514](https://github.com/sahlberg/libnfs/pull/514) |
| network/libnfs | `0576-Do-not-edit-const-and-use-const-qualifier...` | [upstream PR #576](https://github.com/sahlberg/libnfs/pull/576) |
| tools/syslinux | `0001-fix-build-with-glibc-2.28.patch` | Mike Frysinger (Gentoo) |
| addons/addon-depends/rsyslog-depends/snappy | `0086-add-pkg-config-file.patch` | Sebastien Lavoie — [upstream PR #86](https://github.com/google/snappy/pull/86) add CMake pkg-config file |
| addons/addon-depends/steamlink-depends/krb5 | `0001-Fix-strchr-conformance-to-C23.patch` | Alexander Bokovoy (Red Hat) — [upstream ticket #9191](https://bugs.mit.edu/show_bug.cgi?id=9191) |
| addons/addon-depends/steamlink-depends/krb5 | `1485-autoconf-ac-init.patch` | Samuel Cabrero (SUSE) — [upstream ticket #9202](https://bugs.mit.edu/show_bug.cgi?id=9202) autoconf 2.73 compat |
| addons/addon-depends/system-tools-depends/encfs | `0863-build-with-cmake-4.0.0.patch` | Benjamin A. Beasley (Fedora) — CMake 4.0 support |
| addons/service/tigervnc | `1366-raise-cmake-requirement-to-3.10.patch` | Pierre Ossman (TigerVNC maintainer) — [upstream PR #1366](https://github.com/TigerVNC/tigervnc/pull/1366) |
| audio/libcdio | `0001-remove-lfs-shms.patch` | Alfred Wingate (Gentoo) — [Savannah bug #65751](https://savannah.gnu.org/bugs/?65751) rely on `_FILE_OFFSET_BITS=64` |
| lang/nasm | `0152-dirs-dep.patch` | H. Peter Anvin (nasm maintainer) — include PROGOBJ in DIRS dependency |
| network/nftables | `0001-fix-configure-with-non-bash-shell.patch` | Jan Palus / Pablo Neira Ayuso — fix configure with non-bash CONFIG_SHELL |
| security/libxcrypt | `0001-fix-Werror-discarded-qualifiers.patch` | Stanislav Zidek (Red Hat) — remove const casts on strchr return value (GCC strict const) |
| textproc/itstool | `0001-Fix-insufficiently-quoted-regular-expressions.patch` | Nils Philippsen — fix Python 3.12 regex quoting warnings |
| textproc/itstool | `0057-use-lxml-not-libxml2.patch` | Nick Wellnhofer — switch from libxml2 Python bindings to lxml |
| x11/xserver/xorg-server | `1002-add-fedora-extra-modes-list.patch` | Adam Jackson (Red Hat) — extra display mode definitions carried by Fedora |
| addons/addon-depends/network-tools-depends/nmap | `0002-Fix-build-with-OpenSSL-4-x.patch` | Rudi Heitbaum — [PR #3331](https://github.com/nmap/nmap/pull/3331) OpenSSL 4.x build fix |
| devel/crossguid | `0001-pr67-include-missing-cstdint.patch` | Khem Raj (OE) — [upstream PR #67](https://github.com/graeme-hill/crossguid/pull/67) add <cstdint> for GCC 13 |
| devel/elfutils | `0002-libelf--Add-libeu-objects-to-libelf.a-static-archive.patch` | Mark Wielaard (elfutils maintainer) — static archive fix; [Bugzilla #32293](https://sourceware.org/bugzilla/show_bug.cgi?id=32293) |
| devel/gcem | `0054-fix-cmake-minimum~required.patch` | BartolomeyKant — update CMake minimum to 3.10..3.31 |
| devel/gmp | `0001-acinclude.m4-fix-std-c23-build-failure.patch` | upstream GMP hg [18477:8e7bb4ae7a18](https://gmplib.org/repo/gmp/rev/8e7bb4ae7a18) — fix -std=c23 configure test failure |
| devel/heimdal | `1229-cf-largefile.m4-Fix-build-with-autoconf-2.72.patch` | Bernd Kuhls (Buildroot) — fix for [upstream heimdal issue #1201](https://github.com/heimdal/heimdal/issues/1201) |
| devel/libevent | `0001-build-with-cmake-4.0.0.patch` | Azat Khuzhin (libevent author) — require CMake 3.1.2 for OpenSSL detection |
| devel/libevent | `0002-build-with-cmake-4.0.0.patch` | Ingo Bauersachs — make dependency paths relocatable |
| devel/libevent | `0003-build-with-cmake-4.0.0.patch` | Cœur — fix CMake deprecation warning (3.4→3.5) |
| devel/libevent | `0004-build-with-cmake-4.0.0.patch` | Hennadii Stepanov — update CMake minimum to 3.10 |
| devel/make | `0001-fix-large-command-line-on-POSIX-systems.patch` | Mike Crowe — fix long command lines on POSIX; [SV 45763](https://savannah.gnu.org/bugs/?45763) |
| databases/mariadb-connector-c | `0001-fix-build-error-on-32-bit-systems.patch` | Chad Wagner — cast size_t to ulonglong on 32-bit platforms |
| debug/libunwind | `0001-fix-multiple-definition.patch` | [upstream commit 0e74e583](https://github.com/libunwind/libunwind/commit/0e74e583) — add arm_search_unwind_table macro |
| debug/vadumpcaps | `0005-handle-drivers-that-dont-return-any-drm-format-modifi.patch` | Philip Langdale — null check for DRM format modifiers; [upstream issue #4](https://github.com/challlenge/vadumpcaps/issues/4) |

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
