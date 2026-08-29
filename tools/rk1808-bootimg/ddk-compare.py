#!/usr/bin/env python3
"""Measure how far apart releases of VeriSilicon's gc_hal DDK actually are.

Backs the numbers in GALCORE-SOURCE.md, "The lineage, 6.4.6 to 6.4.21".

    python3 ddk-compare.py <label>=<tree> [<label>=<tree> ...]

Each tree is any directory containing the DDK sources; the files are found by
name, so the layout does not have to match between them (ST ships
hal/kernel/gc_hal_kernel_mmu.c, allwinner's bsp ships hal/gc_hal_kernel_mmu.c).

Why not just diff. Three reasons, each found the hard way:

  - 6.4.13 restyled the whole DDK from Allman braces to K&R, dropped the
    IN/OUT/OPTIONAL parameter annotations, and rejoined multi-line prototypes
    onto one line. A raw diff of gc_hal_kernel_hardware.c across that boundary
    reports ~18000 changed lines for a file that does the same thing.
  - the same release moved the mmu declarations out into a new
    gc_hal_kernel_mmu.h, so they read as deleted.
  - ignoring whitespace does not help, because the line boundaries themselves
    moved. It still reports ~50%.

So similarity is measured over shingles - overlapping runs of K tokens - after
stripping comments and the annotation macros. That is insensitive to
reformatting and to code moving within a file, and it is linear, which matters:
these files are ~200k tokens and sequence matching on them does not finish.

Line counts are printed too, because the contrast is the point: the files
shrink in lines across 6.4.13 while growing in tokens.
"""
import os
import re
import sys

BLOCK = re.compile(r"/\*.*?\*/", re.S)
EOL = re.compile(r"//[^\n]*")
TOKEN = re.compile(r"[A-Za-z_][A-Za-z_0-9]*|0[xX][0-9a-fA-F]+|\d+|[^\sA-Za-z_0-9]")

# Expand to nothing, so they are not a difference.
NOISE = {"IN", "OUT", "OPTIONAL", "INOUT"}

K = 7

FILES = ["gc_hal_kernel_mmu.c", "gc_hal_kernel_hardware.c",
         "gc_hal_kernel_command.c", "gc_hal_kernel_video_memory.c"]
SHORT = [f.replace("gc_hal_kernel_", "").replace(".c", "") for f in FILES]


def find(root, name):
    for d, _, fs in os.walk(root):
        if name in fs:
            return os.path.join(d, name)
    return None


def version(root):
    """gcvVERSION_BUILD, so trees from one directory can be told apart."""
    h = find(root, "gc_hal_version.h")
    if not h:
        return "?"
    m = re.search(r"gcvVERSION_BUILD\s+(\d+)", open(h, errors="replace").read())
    return m.group(1) if m else "?"


def tokens(path):
    s = EOL.sub("", BLOCK.sub("", open(path, errors="replace").read()))
    return [t for t in TOKEN.findall(s) if t not in NOISE]


def shingles(t):
    return {tuple(t[i:i + K]) for i in range(max(0, len(t) - K + 1))}


def jaccard(a, b):
    return 100.0 * len(a & b) / len(a | b) if a and b else None


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    trees = []
    for arg in sys.argv[1:]:
        if "=" not in arg:
            raise SystemExit("expected <label>=<tree>, got %r" % arg)
        label, root = arg.split("=", 1)
        if not os.path.isdir(root):
            raise SystemExit("not a directory: %s" % root)
        trees.append((label, root))

    print("  build numbers, so trees from one directory are not confused")
    for label, root in trees:
        print("    %-12s %s" % (label, version(root)))

    lines, shin = {}, {}
    for i, (label, root) in enumerate(trees):
        for f in FILES:
            p = find(root, f)
            if not p:
                lines[(i, f)], shin[(i, f)] = None, set()
                continue
            with open(p, errors="replace") as fh:
                lines[(i, f)] = sum(1 for _ in fh)
            t = tokens(p)
            shin[(i, f)] = shingles(t)
            shin[(i, f, "n")] = len(t)

    def table(title, cell):
        print("\n  %s" % title)
        print("    %-14s %11s %11s %11s %11s" % ("release", *SHORT))
        for i, (label, _) in enumerate(trees):
            print("    %-14s %11s %11s %11s %11s"
                  % (label, *[cell(i, f) for f in FILES]))

    table("lines", lambda i, f: lines[(i, f)] if lines[(i, f)] else "-")
    table("tokens", lambda i, f: shin.get((i, f, "n"), "-"))

    print("\n  shared %d-token shingles, consecutive" % K)
    print("    %-24s %11s %11s %11s %11s" % ("transition", *SHORT))
    for i in range(len(trees) - 1):
        row = []
        for f in FILES:
            v = jaccard(shin[(i, f)], shin[(i + 1, f)])
            row.append("%.1f%%" % v if v is not None else "-")
        print("    %-24s %11s %11s %11s %11s"
              % ("%s -> %s" % (trees[i][0], trees[i + 1][0]), *row))

    print("\n  shared %d-token shingles, against %s" % (K, trees[0][0]))
    print("    %-24s %11s %11s %11s %11s" % ("comparison", *SHORT))
    for i in range(1, len(trees)):
        row = []
        for f in FILES:
            v = jaccard(shin[(0, f)], shin[(i, f)])
            row.append("%.1f%%" % v if v is not None else "-")
        print("    %-24s %11s %11s %11s %11s"
              % ("%s -> %s" % (trees[0][0], trees[i][0]), *row))


if __name__ == "__main__":
    main()
