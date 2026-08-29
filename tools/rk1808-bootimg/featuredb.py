#!/usr/bin/env python3
"""Decode the gcsFEATURE_DATABASE rows embedded in a galcore binary.

galcore carries the chip feature database it was built with as an array of
gcsFEATURE_DATABASE structs. Rockchip never published their tree, but ST and
Amlogic both publish gc_feature_database.h at the same DDK (6.4.6), and the
struct layout is identical across that line - so the public header gives the
field order needed to read the blob's rows field by field.

    python3 featuredb.py <gc_feature_database.h> <galcore.ko> [--diff ID:REV]

The layout is self checking: consecutive rows in the binary must be exactly
sizeof(gcsFEATURE_DATABASE) apart, and the script refuses to decode if they
are not.

The header must come from a 6.4.6 tree. gcsFEATURE_DATABASE is version specific
- 733 members at 6.4.6, 927 at 6.4.21 - so a newer header shifts every field.
A mismatch shows up as rows that are not sizeof() apart, or as rows that fail
the plausibility check, and the script stops rather than printing nonsense.

Header sources (either works, the member list is identical):
    github.com/heitbaum/gcnano-binaries          gcnano-6.4.6-binaries branch,
                                                 inside gcnano-driver-6.4.6.tar.xz
    github.com/heitbaum/npu-driver-amlogic-for-test
                                                 buildroot-ddk-6.4-release,
                                                 hal/kernel/inc/
"""

import json
import re
import struct
import sys


def parse_struct(header):
    """Field order and widths of gcsFEATURE_DATABASE, from the public header."""
    text = open(header, errors="ignore").read()
    m = re.search(r"typedef struct\s*\{(.*?)\}\s*gcsFEATURE_DATABASE;", text, re.S)
    if not m:
        sys.exit("no gcsFEATURE_DATABASE in %s" % header)
    members = []
    for line in m.group(1).splitlines():
        line = line.split("/*")[0].strip()
        bit = re.match(r"gctUINT32\s+(\w+)\s*:\s*(\d+);", line)
        if bit:
            members.append(("bit", bit.group(1), int(bit.group(2))))
            continue
        u32 = re.match(r"gctUINT32\s+(\w+);", line)
        if u32:
            members.append(("u32", u32.group(1), 32))
            continue
        # 6.4.21 added gctUINT32 VIP_SRAM_SIZE_ARRAY[9]. Skipping array members
        # does not merely lose them - every member after one shifts by 4*n
        # bytes, so the whole tail of the row decodes as garbage.
        arr = re.match(r"gctUINT32\s+(\w+)\[(\d+)\];", line)
        if arr:
            members.append(("arr", arr.group(1), int(arr.group(2))))
            continue
        ptr = re.match(r"const char\s*\*\s*(\w+);", line)
        if ptr:
            members.append(("ptr", ptr.group(1), 64))
    return members


def layout(members):
    """Byte offsets for scalars, bit offsets for bitfields; plus struct size."""
    def align(off, n):
        return (off + n - 1) // n * n

    out, off, bitpos = [], 0, None
    for kind, name, width in members:
        if kind == "u32":
            bitpos = None
            off = align(off, 4)
            out.append((name, "u32", off))
            off += 4
        elif kind == "arr":
            bitpos = None
            off = align(off, 4)
            out.append((name, "arr:%d" % width, off))
            off += 4 * width
        elif kind == "ptr":
            bitpos = None
            off = align(off, 8)
            out.append((name, "ptr", off))
            off += 8
        else:
            if bitpos is None or bitpos + width > 32:
                off = align(off, 4)
                off += 4
                bitpos = 0
            out.append((name, "bit", (off - 4) * 8 + bitpos))
            bitpos += width
    return out, align(off, 8)


def parse_entries(header):
    """The rows the header itself ships, keyed on (chipID, chipVersion)."""
    text = open(header, errors="ignore").read()
    body = text[text.index("gChipInfo[] = {"):]
    rows = {}
    for block in re.findall(r"\{\n(.*?)\n    \},", body, re.S):
        vals = []
        for line in block.splitlines():
            v = re.match(r'\s*("(?:[^"]*)"|\{[^}]*\}|0x[0-9a-fA-F]+|\d+),\s*/\*',
                         line)
            if v:
                vals.append(v.group(1))
        if len(vals) > 4:
            rows[(int(vals[0], 0), int(vals[1], 0))] = vals
    return rows


def find_rows(blob, fields, size):
    """Locate rows by identity words, keeping only those correctly spaced."""
    hits = []
    for off in range(0, len(blob) - 16, 4):
        chip_id, rev = struct.unpack_from("<II", blob, off)
        if chip_id in (0x7000, 0x8000, 0x9000) and 0x1000 <= rev <= 0xFFFF:
            hits.append(off)
    rows = []
    for off in hits:
        if any(abs(off - o) % size == 0 and off != o for o in hits):
            rows.append(off)
    # keep the first run of correctly spaced offsets
    return sorted(set(rows))


def plausible(row):
    """Reject identity words that happen to be spaced right but are not a row."""
    def pow2(v):
        return v and not (v & (v - 1))

    return (1 <= row.get("CoreCount", 0) <= 8
            and 1 <= row.get("NumShaderCores", 0) <= 8
            and pow2(row.get("ThreadCount", 0)) and row["ThreadCount"] <= 8192
            and pow2(row.get("TempRegisters", 0)) and row["TempRegisters"] <= 1024
            and row.get("patchVersion", 99) < 16)


def decode(blob, base, lay):
    row = {}
    for name, kind, off in lay:
        if kind.startswith("arr:"):
            n = int(kind.split(":")[1])
            row[name] = list(struct.unpack_from("<%dI" % n, blob, base + off))
        elif kind == "u32":
            row[name] = struct.unpack_from("<I", blob, base + off)[0]
        elif kind == "ptr":
            row[name] = struct.unpack_from("<Q", blob, base + off)[0]
        else:
            word = struct.unpack_from("<I", blob, base + (off // 32) * 4)[0]
            row[name] = (word >> (off % 32)) & 1
    return row


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    header, binary = sys.argv[1], sys.argv[2]
    want = None
    if "--diff" in sys.argv:
        ident = sys.argv[sys.argv.index("--diff") + 1]
        a, b = ident.split(":")
        want = (int(a, 0), int(b, 0))

    members = parse_struct(header)
    lay, size = layout(members)
    kinds = {}
    for k, _, _ in members:
        kinds[k] = kinds.get(k, 0) + 1
    print("struct gcsFEATURE_DATABASE: %d members (%s), %d bytes"
          % (len(members), ", ".join("%d %s" % (v, k) for k, v in kinds.items()), size))

    blob = open(binary, "rb").read()
    offs = find_rows(blob, lay, size)
    if not offs:
        sys.exit("no correctly spaced feature database rows found in %s" % binary)
    runs, rows = [], []
    for o in offs:
        if runs and (o - runs[0]) % size:
            continue
        row = decode(blob, o, lay)
        if plausible(row):
            runs.append(o)
            rows.append(row)
    if not rows:
        sys.exit("rows found but none decoded plausibly - wrong header version?")
    print("%d rows in %s at %s (spacing %d = sizeof, layout confirmed)"
          % (len(runs), binary, ", ".join(hex(o) for o in runs), size))
    for i, row in enumerate(rows):
        print("\nrow %d  chipID 0x%x  chipVersion 0x%x  productID 0x%x  ecoID 0x%x"
              "  customerID 0x%x"
              % (i, row["chipID"], row["chipVersion"], row["productID"],
                 row["ecoID"], row["customerID"]))
        for k in ("NNCoreCount", "NN_ACTIVE_CORE_COUNT", "NNCoreCount_INT8",
                  "NNCoreCount_INT16", "NNCoreCount_FLOAT16", "NNMadPerCore",
                  "TPEngine_CoreCount", "VIP_SRAM_SIZE", "AXI_SRAM_SIZE",
                  "NNInputBufferDepth", "NNAccumBufferDepth",
                  "VIP_V7", "NN_XYDP0", "NN_ZDP3", "TP_ENGINE",
                  "ZRL_7BIT", "ZRL_8BIT", "NN_INTERLEVE8"):
            if k in row:
                print("    %-24s %s" % (k, row[k]))
        # mesa etnaviv_screen.c derives the NN generation from these two bits
        gen = 8 if row.get("NN_XYDP0") else (7 if row.get("VIP_V7") else 6)
        print("    %-24s %d  (mesa etnaviv rule)" % ("NN generation", gen))

    if want:
        pub = parse_entries(header).get(want)
        if not pub:
            sys.exit("no 0x%x/0x%x row in the header" % want)
        names = [n for n, _, _ in lay]
        pub = dict(zip(names, pub))
        print("\ndiff of each binary row against header row 0x%x/0x%x:" % want)
        for i, row in enumerate(rows):
            diff = []
            for n in names:
                if n == "productName" or n not in pub:
                    continue
                v = pub[n]
                v = v if v.startswith('"') else int(v, 0)
                if v != row[n]:
                    diff.append((n, row[n], v))
            print("  row %d: %d of %d members differ" % (i, len(diff), len(names)))
            for n, mine, theirs in diff:
                print("    %-36s %-12s %s" % (n, mine, theirs))

    json.dump([{k: v for k, v in r.items()} for r in rows],
              open("featuredb.json", "w"), indent=1)
    print("\nfull rows written to featuredb.json")


if __name__ == "__main__":
    main()
