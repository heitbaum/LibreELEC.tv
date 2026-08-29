#!/usr/bin/env python3
"""Emit a gcsFEATURE_DATABASE row for this chip and add it to the public header.

The public 6.4.6 headers describe every chip ST and Amlogic ship, and none that
rockchip do. A self built galcore therefore comes up, reads the hardware, and
stops:

    [galcore]: Feature database is not found, chipModel=0x8000,
               chipRevision=0x7100, productID=0x45080001, ecoID=0x0,
               customerID=0x82

The row for that chip does exist - inside rockchip's blob, which carries the
database it was built with. featuredb.py decodes it; this writes it back out as
C in the header's own field order and splices it into gChipInfo[].

    python3 featuredb-emit.py <target.h> <galcore.ko> [chipID:rev] [decode.h]

The struct is not stable across DDK releases - 6.4.6 has 733 members in 456
bytes, 6.4.7 has 745 in 464 - so a row cannot simply be copied between them.
The blob's rows are in the layout it was built with, 6.4.6. Pass that header
as the fourth argument to decode with it while emitting into the target's
field order; members the target has and the source does not are written zero.

Idempotent: a row for the same five ids is replaced rather than duplicated.
"""
import re
import sys

import featuredb


def emit_row(row, lay, label):
    """One C initialiser, positional, in the *target* header's order.

    Values come from the decoded row by name. A member the target declares and
    the decoding layout does not gets zero, which is what a chip predating that
    feature should read as.
    """
    out = ["    /* %s */" % label, "    {"]
    for n, kind, _ in lay:
        v = row.get(n)
        if n == "productName":
            out.append('        "", /* ProductName */')
            continue
        # An array member must be braced. Unbraced it does not just warn - the
        # next n values are consumed as its elements and every member after
        # that lands in the wrong field. 6.4.21's VIP_SRAM_SIZE_ARRAY[9] is the
        # first of these; upstream rows leave it {0x0, } and carry the value in
        # the scalar VIP_SRAM_SIZE beside it, so a chip that predates the array
        # is correct with zeros.
        if kind.startswith("arr:"):
            out.append("        {0x0, }, /* gcFEATURE_VALUE_%s */" % n)
            continue
        if v is None:
            v = 0
        comment = {
            "chipID": "ChipID", "chipVersion": "ChipRevision",
            "productID": "ProductID", "ecoID": "EcoID",
            "customerID": "CustomerID", "patchVersion": "PatchVersion",
            "formalRelease": "FormalRelease",
        }.get(n, "gcFEATURE_VALUE_" + n if not n.startswith("gcFEATURE") else n)
        out.append("        0x%x, /* %s */" % (v, comment))
    out.append("    },")
    return "\n".join(out)


def main():
    if len(sys.argv) not in (3, 4, 5):
        raise SystemExit(__doc__)
    header, binary = sys.argv[1], sys.argv[2]
    want = None
    if len(sys.argv) >= 4 and sys.argv[3] != "-":
        a, b = sys.argv[3].split(":")
        want = (int(a, 0), int(b, 0))
    decode_header = sys.argv[4] if len(sys.argv) == 5 else header

    # decode with the layout the blob was built against
    lay, size = featuredb.layout(featuredb.parse_struct(decode_header))
    # emit in the order the target header declares
    tgt_lay, tgt_size = featuredb.layout(featuredb.parse_struct(header))
    names = [n for n, _, _ in tgt_lay]
    if decode_header != header:
        print("  decoding with %d members / %d bytes, emitting %d / %d"
              % (len(lay), size, len(tgt_lay), tgt_size))

    blob = open(binary, "rb").read()
    offs = featuredb.find_rows(blob, lay, size)
    rows = []
    for o in offs:
        r = featuredb.decode(blob, o, lay)
        if featuredb.plausible(r):
            rows.append(r)
    if not rows:
        raise SystemExit("no rows decoded from %s" % binary)

    if want:
        rows = [r for r in rows
                if (r["chipID"], r["chipVersion"]) == want]
        if not rows:
            raise SystemExit("no row for 0x%x:0x%x" % want)
    row = rows[0]

    label = "rk1808_0x%x_0x%x from %s" % (
        row["chipID"], row["chipVersion"], binary.split("/")[-1])
    c = emit_row(row, tgt_lay, label)

    text = open(header).read()
    marker = "static gcsFEATURE_DATABASE gChipInfo[] = {"
    if marker not in text:
        raise SystemExit("no gChipInfo[] in %s" % header)

    # drop any row we added before, so this can be re-run
    text = re.sub(r"    /\* rk1808_0x[0-9a-f]+_0x[0-9a-f]+[^\n]*\*/\n    \{.*?\n    \},\n",
                  "", text, flags=re.S)

    text = text.replace(marker, marker + "\n" + c, 1)
    open(header, "w").write(text)

    print("  added row chipID 0x%x rev 0x%x product 0x%x eco 0x%x customer 0x%x"
          % (row["chipID"], row["chipVersion"], row["productID"],
             row["ecoID"], row["customerID"]))
    print("  %d members written, NNCoreCount %s, VIP_V7 %s, NN_XYDP0 %s"
          % (len(names), row.get("NNCoreCount"), row.get("VIP_V7"),
             row.get("NN_XYDP0")))
    print("  gChipInfo[] now has %d rows" % text.count("/* ChipID */"))


if __name__ == "__main__":
    main()
