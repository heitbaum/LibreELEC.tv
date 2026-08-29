#!/usr/bin/env python3
"""Compare the galcore ioctl ABI between two DDK releases.

Backs GALCORE-SOURCE.md, "6.4.21 builds, loads, and then wedges the die".

    python3 ddk-abi.py 6.4.6=<tree> 6.4.21=<tree>

The userspace on the RK1808 - librknn_api on the host, rknn_server on the die -
was compiled against 6.4.6's headers and is binary only, so it cannot be
rebuilt. Every ioctl it sends is a gcsHAL_INTERFACE whose layout those headers
fixed. This checks the three things that have to match for a newer driver to
understand it:

  1. the fixed head of gcsHAL_INTERFACE, read before any command dispatch
  2. gceHAL_COMMAND_CODES, whose *position* is the command number - the enum
     carries no explicit values, so an insertion renumbers everything after it
  3. the per-command payload structs, which the command number does not
     describe and which a mismatched driver will happily read at the wrong
     offsets

1 and 2 turn out to be intact between 6.4.6 and 6.4.21. 3 is not, which is why
a 6.4.21 driver gets as far as loading and then destroys the first real
request.
"""
import os
import re
import sys

BLOCK = re.compile(r"/\*.*?\*/", re.S)
NOISE = {"IN", "OUT", "OPTIONAL", "INOUT"}


def find(root, name, under=""):
    for d, _, fs in os.walk(root):
        if name in fs and under in d.replace("\\", "/"):
            return os.path.join(d, name)
    return None


def source(root, name):
    p = find(root, name, "shared")
    if not p:
        raise SystemExit("no %s under %s" % (name, root))
    return BLOCK.sub("", open(p, errors="replace").read())


def fields(body):
    out = []
    for line in body.splitlines():
        line = re.sub(r"//.*", "", line).strip()
        if not line.endswith(";"):
            continue
        out.append(" ".join(t for t in re.split(r"\s+", line.rstrip(";"))
                            if t not in NOISE))
    return out


def command_codes(root):
    """Position is the ABI: this enum has no explicit values."""
    s = source(root, "gc_hal_enum_shared.h")
    m = re.search(r"typedef enum _gceHAL_COMMAND_CODES\s*\{(.*?)\}", s, re.S)
    if not m:
        return []
    out = []
    for line in m.group(1).splitlines():
        n = re.match(r"\s*(gcvHAL_[A-Z_0-9]+)", re.sub(r"//.*", "", line))
        if n:
            out.append(n.group(1))
    return out


def payloads(root):
    s = source(root, "gc_hal_driver_shared.h")
    out = {}
    for m in re.finditer(r"typedef struct _(gcsHAL_[A-Za-z_0-9]+)\s*\{(.*?)\}\s*\1;",
                         s, re.S):
        out[m.group(1)] = fields(m.group(2))
    return out


def interface_head(root):
    """The fields read before the union - i.e. before any command dispatch.

    Split on the union keyword rather than filtering by type name: there are
    plain fields after the union too, and counting those makes the head look
    like it changed when it did not.
    """
    s = source(root, "gc_hal_driver_shared.h")
    m = re.search(r"typedef struct _gcsHAL_INTERFACE\s*\{(.*?)\}\s*gcsHAL_INTERFACE;",
                  s, re.S)
    if not m:
        return []
    return fields(m.group(1).split("union", 1)[0])


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    (la, ra), (lb, rb) = [a.split("=", 1) for a in sys.argv[1:]]

    print("== gcsHAL_INTERFACE fixed head")
    heads = {}
    for label, root in ((la, ra), (lb, rb)):
        heads[label] = interface_head(root)
        print("   %-10s %d fields before the union" % (label, len(heads[label])))
    print("   identical: %s" % (heads[la] == heads[lb]))
    if heads[la] != heads[lb]:
        for i in range(max(len(heads[la]), len(heads[lb]))):
            x = heads[la][i] if i < len(heads[la]) else "-"
            y = heads[lb][i] if i < len(heads[lb]) else "-"
            if x != y:
                print("      %2d  %-44s | %s" % (i, x, y))

    print("\n== gceHAL_COMMAND_CODES")
    ca, cb = command_codes(ra), command_codes(rb)
    print("   %-10s %d codes" % (la, len(ca)))
    print("   %-10s %d codes" % (lb, len(cb)))
    shared = [x for x in ca if x in cb]
    moved = [(x, ca.index(x), cb.index(x)) for x in shared
             if ca.index(x) != cb.index(x)]
    for i in range(min(len(ca), len(cb))):
        if ca[i] != cb[i]:
            print("   diverge at index %d: %s / %s" % (i, ca[i], cb[i]))
            break
    else:
        print("   no divergence in the common prefix")
    print("   %d of %d shared codes changed position" % (len(moved), len(shared)))
    for x, i, j in moved:
        print("     %-44s %3d -> %3d" % (x, i, j))

    print("\n== per-command payload structs")
    A, B = payloads(ra), payloads(rb)
    A.pop("gcsHAL_INTERFACE", None)
    B.pop("gcsHAL_INTERFACE", None)
    both = sorted(set(A) & set(B))
    diff = [k for k in both if A[k] != B[k]]
    print("   %-10s %d structs" % (la, len(A)))
    print("   %-10s %d structs" % (lb, len(B)))
    print("   identical %d, changed %d" % (len(both) - len(diff), len(diff)))
    for k in diff:
        print("\n   == %s" % k)
        fa, fb = A[k], B[k]
        for i in range(max(len(fa), len(fb))):
            x = fa[i] if i < len(fa) else "-"
            y = fb[i] if i < len(fb) else "-"
            if x != y:
                print("      %2d  %-44s | %s" % (i, x, y))


if __name__ == "__main__":
    main()
