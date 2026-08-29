#!/usr/bin/env python3
"""Rockchip RSCE resource image - unpack and repack.

The boot image's second area is not a raw dtb. It is a rockchip resource
image holding rk-kernel.dtb and the boot logos, so the dtb cannot be replaced
without going through this container.

Layout, all offsets in 512 byte blocks:

    header   magic "RSCE", versions, header_size, tbl_offset,
             tbl_entry_size, tbl_entry_num
    entry    tag "ENTR", name[256], offset, size     (one per file)
"""
import os
import struct
import sys

BLOCK = 512
HDR = struct.Struct("<4sHHBBBBI")      # magic, ptn_ver, tbl_ver, hdr, tbl_off, ent_sz, pad, n
ENT = struct.Struct("<4s256sII")       # tag, name, offset, size


def read_header(blob):
    magic, pv, tv, hdr_sz, tbl_off, ent_sz, _pad, n = HDR.unpack_from(blob, 0)
    if magic != b"RSCE":
        raise SystemExit("not a resource image: magic %r" % magic)
    return dict(ptn_version=pv, tbl_version=tv, header_size=hdr_sz,
                tbl_offset=tbl_off, entry_size=ent_sz, count=n)


def entries(blob, h):
    for i in range(h["count"]):
        off = (h["tbl_offset"] + i * h["entry_size"]) * BLOCK
        tag, name, blk, size = ENT.unpack_from(blob, off)
        if tag != b"ENTR":
            raise SystemExit("entry %d has tag %r" % (i, tag))
        yield name.rstrip(b"\0").decode(), blk, size


def unpack(img, outdir):
    blob = open(img, "rb").read()
    h = read_header(blob)
    os.makedirs(outdir, exist_ok=True)
    names = []
    for name, blk, size in entries(blob, h):
        data = blob[blk * BLOCK: blk * BLOCK + size]
        path = os.path.join(outdir, name.replace("/", "_"))
        open(path, "wb").write(data)
        print("  %-24s %8d bytes" % (name, size))
        names.append(name)
    with open(os.path.join(outdir, "resource.list"), "w") as f:
        f.write("\n".join(names) + "\n")


def repack(indir, img):
    names = [l.strip() for l in open(os.path.join(indir, "resource.list")) if l.strip()]
    n = len(names)
    # header block, then one block per entry, then the payloads
    first = 1 + n
    out = bytearray(first * BLOCK)
    HDR.pack_into(out, 0, b"RSCE", 0, 0, 1, 1, 1, 0, n)

    blk = first
    for i, name in enumerate(names):
        data = open(os.path.join(indir, name.replace("/", "_")), "rb").read()
        ENT.pack_into(out, (1 + i) * BLOCK, b"ENTR", name.encode(), blk, len(data))
        out += data
        pad = (-len(data)) % BLOCK
        out += b"\0" * pad
        blk += (len(data) + pad) // BLOCK
        print("  %-24s %8d bytes" % (name, len(data)))
    open(img, "wb").write(bytes(out))
    print("  wrote %s  %d bytes" % (img, len(out)))


if __name__ == "__main__":
    if len(sys.argv) != 4 or sys.argv[1] not in ("unpack", "repack"):
        raise SystemExit("usage: resource.py {unpack <img> <dir> | repack <dir> <img>}")
    (unpack if sys.argv[1] == "unpack" else repack)(sys.argv[2], sys.argv[3])
