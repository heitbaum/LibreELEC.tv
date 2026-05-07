# Syslinux Replacement — Mini-Project Notes

## Background

Syslinux 6.03 is the last release (2016). The project is dead — no upstream patches, no security fixes, no new hardware support. LibreELEC currently uses syslinux for Generic x86_64 to provide dual-mode boot: BIOS (via `gptmbr.bin` + mtools install) and UEFI 64-bit (via `bootx64.efi` / `ldlinux.e64`). GRUB 2.x is built alongside it to provide `bootia32.efi` for boards with 32-bit EFI firmware (older Intel Atom).

Discussed in the LE13 planning issue: https://github.com/LibreELEC/LibreELEC.tv/issues/8184

## Decision: UEFI-only for LE13

The team agreed (CvH, HiassofT, chewitt, heitbaum — Aug/Sep 2024) that UEFI-only is acceptable for LE13:

- UEFI CSM covers anything less than ~10 years old
- Users on ancient BIOS-only hardware can install LE12 first; LE13 updates only replace `KERNEL` and `SYSTEM` and leave the boot partition untouched, so the existing BIOS boot setup continues to work post-update
- Going forward without UEFI is not a real option

## Candidates Evaluated

### Barebox (u-boot fork)

- Maintained, well documented: https://barebox.org/
- Initially attractive as a modern alternative
- **Dropped**: x86 legacy BIOS boot support was removed in barebox 2021.05
  (http://lists.infradead.org/pipermail/barebox/2021-May/036126.html)
- EFI-only path exists: https://www.barebox.org/doc/latest/boards/efi.html
- Not pursued further — added complexity with no clear advantage over the options below

### Syslinux UEFI-only

- The existing syslinux package already ships `bootx64.efi` / `ldlinux.e64`
- Hack-tested UEFI-only mode on BeeLink SER7 — works
- Avoids replacing the bootloader entirely while dropping dead BIOS code
- Downside: syslinux is still dead upstream; eventually needs replacing anyway

### systemd-boot (sd-boot)

- Part of systemd; already maintained as part of the systemd project
- LibreELEC already builds it: commit `3c8c56c8` (2024-08-31) added
  `-Dbootloader=enabled` to the systemd meson build for Generic x86_64
- `systemd-boot.efi` (installed as `bootx64.efi`) is built but **not yet
  wired into the image**
- systemd-boot requires a UEFI System Partition and uses Type 1 Boot Loader
  Specification entries (`.conf` files in `/loader/entries/`)
- The systemd project also has additional UEFI utilities to investigate
  (e.g. `systemd-stub`, unified kernel images)
- Most likely path forward

## Current Tree State

### What is already in place

| File | Role |
|------|------|
| `packages/tools/syslinux/package.mk` | syslinux 6.03 — builds `bootx64.efi`, `ldlinux.e64`, `gptmbr.bin`, `syslinux.mtools` |
| `packages/tools/grub/package.mk` | grub 2.14 — builds `bootia32.efi` only (32-bit EFI for Atom boards) |
| `packages/sysutils/systemd/package.mk:105` | `-Dbootloader=enabled` + `pyelftools:host` dep for Generic — systemd-boot binary is built |
| `scripts/mkimage` | Image assembly; see below |
| `projects/Generic/options` | `BOOTLOADER="syslinux"` |
| `packages/tools/installer/package.mk` | Depends on `syslinux` and `grub` |

### `scripts/mkimage` boot assembly (syslinux path)

```
Line 84:  dd gptmbr.bin → first 440 bytes of disk (BIOS MBR bootstrap)
Line 140: writes syslinux.cfg to FAT root (BIOS menu)
Line 166: writes grub.cfg to /EFI/BOOT (UEFI menu)
Line 187: syslinux.mtools -i part1.fat (installs BIOS bootloader to FAT)
Line 197: mcopy bootx64.efi  → /EFI/BOOT (syslinux UEFI 64-bit)
Line 198: mcopy ldlinux.e64  → /EFI/BOOT (syslinux UEFI 64-bit loader)
Line 199: mcopy bootia32.efi → /EFI/BOOT (grub UEFI 32-bit for Atom)
Line 200: mcopy grub.cfg     → /EFI/BOOT
```

Boot menu entries (both syslinux.cfg and grub.cfg): **Installer**, **Live**, **Run**

### What is NOT yet done

- systemd-boot `.efi` is built but not placed in the image
- `scripts/mkimage` has no systemd-boot code path
- `projects/Generic/options` still sets `BOOTLOADER="syslinux"`
- `packages/tools/installer` still depends on syslinux/grub
- No `.conf` loader entries written by mkimage
- OVA image creation still patches `syslinux.cfg` / `grub.cfg` (lines 301-304)

## Work Required to Switch to systemd-boot

1. **`scripts/mkimage`** — add a `systemd-boot` code path:
   - Skip `gptmbr.bin` MBR write (UEFI-only; no BIOS bootstrap needed)
   - Skip `syslinux.mtools` install
   - Copy `${TOOLCHAIN}/usr/lib/systemd/boot/efi/systemd-bootx64.efi` → `/EFI/BOOT/bootx64.efi`
   - Write `/loader/loader.conf` (timeout, default entry)
   - Write `/loader/entries/libreelec-installer.conf`, `libreelec-live.conf`, `libreelec-run.conf`
     (each: `title`, `linux /KERNEL`, `options boot=UUID=… …`)
   - Keep `bootia32.efi` (grub) for 32-bit EFI Atom boards, or drop once confirmed unnecessary

2. **`projects/Generic/options`** — change `BOOTLOADER="syslinux"` to `BOOTLOADER="systemd-boot"`
   (or a new value that mkimage understands)

3. **`packages/tools/installer/package.mk`** — update deps; remove syslinux/grub if no longer needed
   by the installer runtime

4. **`packages/tools/syslinux`** — evaluate: retire entirely, or keep reduced (UEFI files only for
   any remaining use in installer flow)

5. **OVA image** (lines 298-304 in mkimage) — update to patch loader entry instead of syslinux.cfg

6. **Testing matrix**:
   - Fresh USB install → run from disk
   - Live/portable boot
   - Update from LE12 (BIOS boot install) — boot partition left intact, LE13 kernel/system loads
   - UEFI 32-bit Atom board (if keeping `bootia32.efi`)
   - VM (QEMU/VirtualBox) UEFI boot
   - Secure Boot (future — systemd-boot supports it; syslinux does not)

## systemd-boot loader entry format

```ini
# /loader/entries/libreelec-run.conf
title   LibreELEC (Run)
linux   /KERNEL
options boot=UUID=<SYSTEM_UUID> disk=UUID=<STORAGE_UUID> quiet
```

```ini
# /loader/loader.conf
timeout 5
default libreelec-installer.conf
```

## Notes

- systemd-boot requires the EFI System Partition to be mounted at `/efi` or `/boot` at runtime
  for `bootctl` updates. LibreELEC mounts it at `/flash` — check if `bootctl` update flow is
  needed or if we just install the `.efi` during image build and never update it from the OS.
- The `grub_live` / `grub_portable` kernel parameters in the current `grub.cfg` are
  LibreELEC-specific hooks in the init scripts. With systemd-boot the equivalent parameters
  need to be in the loader entry `options` line — confirm init scripts handle both or update them.
- Secure Boot: systemd-boot can be signed; syslinux cannot. This is a future benefit of switching.
