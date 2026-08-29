#!/usr/bin/env python3
"""Unpack and repack the rk1808 android boot image.

The rk1808 has no storage: maskrom downloads this image into RAM on every
power cycle, so a bad image cannot brick anything - it just fails to boot and
a power cycle puts the die back in maskrom.
"""
import os, struct, sys, json, hashlib

MAGIC = b"ANDROID!"
HDR = "<8s10I16s512s8I1024s"

def _pad(n, page):
    return (page - (n % page)) % page

def unpack(img, outdir):
    d = open(img, "rb").read()
    if d[:8] != MAGIC:
        sys.exit("not an android boot image")
    f = struct.unpack_from(HDR, d, 0)
    (magic, ksz, kaddr, rsz, raddr, ssz, saddr, tags, page, hdrv, osver,
     name, cmdline) = f[:13]
    extra = f[21]
    os.makedirs(outdir, exist_ok=True)
    meta = dict(kernel_addr=kaddr, ramdisk_addr=raddr, second_addr=saddr,
                tags_addr=tags, page_size=page, header_version=hdrv,
                os_version=osver, name=name.rstrip(bytes(1)).decode(),
                cmdline=cmdline.rstrip(bytes(1)).decode(),
                extra_cmdline=extra.rstrip(bytes(1)).decode())
    off = page
    for what, sz in (("kernel", ksz), ("ramdisk", rsz), ("second", ssz)):
        if sz:
            open(os.path.join(outdir, what), "wb").write(d[off:off + sz])
            off += sz + _pad(sz, page)
        meta[what + "_size"] = sz
    json.dump(meta, open(os.path.join(outdir, "manifest.json"), "w"), indent=2)
    for k, v in meta.items():
        print("  %-16s %s" % (k, hex(v) if isinstance(v, int) else v))

def repack(indir, out):
    meta = json.load(open(os.path.join(indir, "manifest.json")))
    page = meta["page_size"]
    parts = {}
    for what in ("kernel", "ramdisk", "second"):
        p = os.path.join(indir, what)
        parts[what] = open(p, "rb").read() if os.path.exists(p) else b""

    # android id[]: sha1 over each part followed by its length
    sha = hashlib.sha1()
    for what in ("kernel", "ramdisk", "second"):
        sha.update(parts[what])
        sha.update(struct.pack("<I", len(parts[what])))
    ident = struct.unpack("<8I", sha.digest() + bytes(12))

    hdr = struct.pack(
        HDR, MAGIC,
        len(parts["kernel"]),  meta["kernel_addr"],
        len(parts["ramdisk"]), meta["ramdisk_addr"],
        len(parts["second"]),  meta["second_addr"],
        meta["tags_addr"], page, meta["header_version"], meta["os_version"],
        meta["name"].encode().ljust(16, bytes(1)),
        meta["cmdline"].encode().ljust(512, bytes(1)),
        *ident,
        meta["extra_cmdline"].encode().ljust(1024, bytes(1)))
    with open(out, "wb") as fh:
        fh.write(hdr); fh.write(bytes(_pad(len(hdr), page)))
        for what in ("kernel", "ramdisk", "second"):
            b = parts[what]
            if b:
                fh.write(b); fh.write(bytes(_pad(len(b), page)))
    print("  wrote %s  %d bytes" % (out, os.path.getsize(out)))
    for what in ("kernel", "ramdisk", "second"):
        print("    %-8s %d" % (what, len(parts[what])))

if __name__ == "__main__":
    if len(sys.argv) != 4 or sys.argv[1] not in ("unpack", "repack"):
        sys.exit("usage: bootimg.py {unpack <img> <dir> | repack <dir> <img>}")
    (unpack if sys.argv[1] == "unpack" else repack)(sys.argv[2], sys.argv[3])
