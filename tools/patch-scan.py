#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)

"""patch-scan - reconcile PATCHES.md against the actual patch tree.

Checks both directions so PATCHES.md stays honest:

  STALE      a patch named in PATCHES.md whose file no longer exists
             (checked against both the reference ref and dev, since dev
             carries WIP that is intentionally not yet on master)
  UNTRACKED  a patch carried in the tree that is neither named in
             PATCHES.md nor covered by an "Intentionally local" package row

Packages/trees excluded from tracking (per PATCHES.md "Exceptions"):
kodi, linux/, docker/moby, podman, and the large ffmpeg rpi patch.

Run from the repo root. Exits non-zero when the reference ref has any
stale or untracked patch, so it can be used as a CI guard.

  tools/patch-scan.py                 # check master (default)
  tools/patch-scan.py --ref HEAD      # check the current branch
  tools/patch-scan.py --dev           # also list dev-only untracked patches
"""

import argparse
import os
import re
import subprocess
import sys

EXCLUDE_PREFIX = (
    "packages/mediacenter/kodi/",
    "packages/linux/",
    "packages/addons/addon-depends/docker/moby/patches/",
    "packages/addons/addon-depends/podman/",
)
EXCLUDE_EXACT = {"packages/multimedia/ffmpeg/patches/rpi/0001-rpi.patch"}


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True)


def tree_patches(ref):
    out = git("ls-tree", "-r", "--name-only", ref).stdout.splitlines()
    return [p for p in out if p.startswith("packages/")
            and "/patches/" in p and p.endswith(".patch")]


def pkg_of(path):
    return path.split("packages/", 1)[1].split("/patches/", 1)[0]


def leaf(pkg):
    return pkg.rstrip("/").split("/")[-1]


def parse_patches_md(path):
    """Return (named, le_pkgs, malformed).

    named   list of (section, pkg, leaf, basename)
    le_pkgs set of packages tracked by count in "Intentionally local"
    malformed rows in a patch section whose cell looks like a patch
              reference but does not end in .patch (e.g. truncated)
    """
    section = None
    named, le_pkgs, malformed = [], set(), []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            m = re.match(r"^#{2,4}\s+(.*)", line)
            if m:
                section = m.group(1).strip()
                continue
            if not line.startswith("|"):
                continue
            cols = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cols) < 3 or cols[0] == "Package" or set(cols[0]) <= set("-"):
                continue
            pkg = cols[0].split()[0]
            if "Intentionally local" in (section or "") and cols[1].isdigit():
                le_pkgs.add(pkg)
                continue
            m2 = re.search(r"`?([^`\s]+\.patch)`?", cols[1])
            if m2:
                named.append((section, pkg, leaf(pkg), os.path.basename(m2.group(1))))
            elif re.search(r"[0-9]{3,4}[-.]", cols[1]):
                malformed.append((section, pkg, cols[1]))
    return named, le_pkgs, malformed


def found(treeset, pkg_leaf, base):
    key = f"/{pkg_leaf}/patches/"
    return any(key in p and os.path.basename(p) == base for p in treeset)


def main():
    ap = argparse.ArgumentParser(description="reconcile PATCHES.md with the tree")
    ap.add_argument("--ref", default="master",
                    help="git ref to treat as the tracked tree (default: master)")
    ap.add_argument("--file", default="PATCHES.md", help="path to PATCHES.md")
    ap.add_argument("--dev", action="store_true",
                    help="also list patches carried only on dev but untracked")
    args = ap.parse_args()

    named, le_pkgs, malformed = parse_patches_md(args.file)
    le_leaves = {leaf(p) for p in le_pkgs}
    ref_set = set(tree_patches(args.ref))
    dev_set = set(tree_patches("dev"))
    both = ref_set | dev_set

    print(f"named rows: {len(named)} | le-specific packages: {len(le_pkgs)} | "
          f"{args.ref} patches: {len(ref_set)} | dev patches: {len(dev_set)}\n")

    rc = 0

    stale = [(s, pkg, base) for (s, pkg, lf, base) in named
             if not found(both, lf, base)]
    print(f"=== STALE ({len(stale)}): named in PATCHES.md, file gone from {args.ref} and dev ===")
    for s, pkg, base in stale:
        print(f"  [{s}] {pkg} :: {base}")
    if stale:
        rc = 1

    # le-specific rows are tracked by count, not filename: flag any whose
    # package no longer has a single patch in the tree
    le_leaves_with_patch = {leaf(pkg_of(p)) for p in both}
    le_stale = sorted(p for p in le_pkgs if leaf(p) not in le_leaves_with_patch)
    print(f"\n=== STALE le-specific ({len(le_stale)}): package row but no patch in tree ===")
    for p in le_stale:
        print(f"  {p}")
    if le_stale:
        rc = 1

    named_keys = {(lf, base) for (_, _, lf, base) in named}
    untracked = []
    for p in sorted(ref_set):
        if p.startswith(EXCLUDE_PREFIX) or p in EXCLUDE_EXACT:
            continue
        pkg = pkg_of(p)
        if (leaf(pkg), os.path.basename(p)) in named_keys:
            continue
        if pkg in le_pkgs or leaf(pkg) in le_leaves:
            continue
        untracked.append(p)
    print(f"\n=== UNTRACKED on {args.ref} ({len(untracked)}): carried, not tracked ===")
    for p in untracked:
        print(f"  {p}")
    if untracked:
        rc = 1

    if malformed:
        print(f"\n=== MALFORMED ({len(malformed)}): patch cell not a valid filename ===")
        for s, pkg, cell in malformed:
            print(f"  [{s}] {pkg} :: {cell}")

    # informational: named patches on dev but not on the reference ref
    devonly = [(s, pkg, base) for (s, pkg, lf, base) in named
               if found(dev_set, lf, base) and not found(ref_set, lf, base)]
    print(f"\n=== dev-only WIP (tracked, on dev, not on {args.ref}) (informational) ===")
    for s, pkg, base in devonly:
        print(f"  [{s}] {pkg} :: {base}")

    if args.dev:
        print("\n=== UNTRACKED on dev (carried on dev, not tracked) (informational) ===")
        for p in sorted(dev_set - ref_set):
            if p.startswith(EXCLUDE_PREFIX) or p in EXCLUDE_EXACT:
                continue
            pkg = pkg_of(p)
            if (leaf(pkg), os.path.basename(p)) in named_keys:
                continue
            if pkg in le_pkgs or leaf(pkg) in le_leaves:
                continue
            print(f"  {p}")

    print(f"\n{'OK' if rc == 0 else 'FAIL'}: {args.ref} has "
          f"{len(stale)} stale and {len(untracked)} untracked patches.")
    return rc


if __name__ == "__main__":
    sys.exit(main())
