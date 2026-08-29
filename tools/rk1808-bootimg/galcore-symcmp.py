#!/usr/bin/env python3
"""Compare two galcore modules by defined function.

Used to answer whether rockchip's 351518 blob differs from a 342038 build by
anything other than the version number it reports. See GALCORE-SOURCE.md,
"What 351518 has that 342038 does not".

    python3 galcore-symcmp.py <vendor.ko> <ours.ko> [nm-prefix]

Neither module is stripped of anything useful - galcore keeps its static
function names in .symtab - so the defined-function sets compare directly.

The one thing that must be done first is folding away gcc's clone suffixes.
gcc emits a specialised copy of a function for a call site whose arguments it
knows, and names it .isra.N, .constprop.N, .part.N. Which clones exist depends
on the compiler, not on the source: the vendor blob is gcc 6.3 and a build here
is gcc 15. Compared raw, the two sets look far more different than they are.

The suffixes nest - _ProgramTPOutput.isra.7.constprop.25 is real - so the fold
has to be applied until it stops changing. Stripping one suffix leaves
_ProgramTPOutput.isra.7, which then reads as a difference against a
_ProgramTPOutput.constprop.0 on the other side when it is the same function.
"""
import re
import subprocess
import sys
from collections import defaultdict

SUFFIX = re.compile(r"\.(isra|constprop|part|cold|lto_priv|localalias)(\.\d+)*$")


def base(name):
    """Fold gcc clone suffixes away, however many are stacked up."""
    while True:
        stripped = SUFFIX.sub("", name)
        if stripped == name:
            return name
        name = stripped

# Rough grouping, so the output separates the plumbing from the features. A
# function landing in "other" is not necessarily interesting; the point of the
# buckets is that sysfs/debugfs and drm differences are build configuration and
# should not be read as missing hardware support.
BUCKETS = (
    ("sysfs",           ("_show", "_store", "sysfs")),
    ("debugfs",         ("debugfs",)),
    ("devfreq / power", ("devfreq", "power")),
    ("dma-buf / drm",   ("dmabuf", "dma_buf", "drm", "fence", "gem")),
)


def funcs(path, prefix):
    """Every function this module defines, clone suffixes folded away."""
    out = subprocess.run([prefix + "nm", path], capture_output=True, text=True)
    if out.returncode:
        raise SystemExit("%snm failed on %s: %s" % (prefix, path, out.stderr.strip()))
    s = set()
    for line in out.stdout.splitlines():
        p = line.split()
        # 't' is a local function, 'T' a global one; both are defined here
        if len(p) >= 3 and p[1] in ("t", "T"):
            s.add(base(p[2]))
    return s


def bucket(names):
    b = defaultdict(list)
    for n in sorted(names):
        low = n.lower()
        for label, keys in BUCKETS:
            if any(k in low for k in keys):
                b[label].append(n)
                break
        else:
            b["other"].append(n)
    return b


def main():
    if len(sys.argv) not in (3, 4):
        raise SystemExit(__doc__)
    a, b = sys.argv[1], sys.argv[2]
    prefix = sys.argv[3] if len(sys.argv) == 4 else "aarch64-linux-gnu-"

    fa, fb = funcs(a, prefix), funcs(b, prefix)
    print("  %-40s %4d functions" % (a, len(fa)))
    print("  %-40s %4d functions" % (b, len(fb)))
    print("  common %d, first only %d, second only %d"
          % (len(fa & fb), len(fa - fb), len(fb - fa)))

    for label, names in (("only in " + a, fa - fb), ("only in " + b, fb - fa)):
        print("\n  --- %s ---" % label)
        for k, v in sorted(bucket(names).items()):
            print("    %-16s %d: %s" % (k, len(v), ", ".join(v)))


if __name__ == "__main__":
    main()
