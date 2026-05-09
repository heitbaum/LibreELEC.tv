# LibreELEC.tv — Claude Code guidance

## Patch file naming convention

All patch files under `packages/` (except `packages/mediacenter/kodi`) must follow:

```
packagename-####-subject.patch
```

### Rules

- **Package name**: must match the directory name immediately before `patches/`
- **Number**: exactly 4 digits, zero-padded (`0001`–`9999`); `0000` is not valid
- **Subject**: `git format-patch` style — hyphens as word separators, no underscores, max 53 characters
- **Separator**: hyphen between every component

### Numbering

- Sequences start at `0001` — never `0000`
- Within a package, low numbers (`< 100`) must be sequential from `0001` with no gaps
- High numbers (≥ 100) are often upstream PR/commit references and may be non-sequential — this is intentional
- No duplicate numbers within the same patches directory

### Subject

- Use hyphens, not underscores: `fix-build-with-gcc-14` not `fix_build_with_gcc_14`
- Maximum 53 characters (matches `git format-patch` default)
- Derive from the git `Subject:` header where it is more descriptive than a hand-written label
- Do not repeat the package name in the subject: `pkg-0001-fix-build.patch` not `pkg-0001-pkg-fix-build.patch`
- Do not include upstream tracker/mailing-list noise (`SV-12345-`, `[FFmpeg-devel]`, etc.)

### Exceptions

- `packages/mediacenter/kodi` — excluded from all treewide rename rules
- `packages/linux/patches/rockchip/` and `packages/linux/patches/rockchip-old/` — left with their original `rockchip-NNNN-` naming

### Verification

Run `rename_plan.py` (repo root) to check conformance:

```bash
python3 rename_plan.py            # dry-run: print proposed renames + warnings
python3 rename_plan.py --execute  # execute git mv commands
```

## Commit discipline

- One concern per commit — never bundle unrelated changes
- New `package.mk` files use `GPL-2.0-only` licence, not `GPL-2.0-or-later`
