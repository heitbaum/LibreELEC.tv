#!/usr/bin/env python3
"""Teach the 6.4.6 DDK about kernel APIs that changed after it was written.

    python3 galcore-modern.py <galcore-source-tree>

Called by build-galcore.sh. Idempotent.

Why this exists rather than moving to a newer DDK: on 6.12 you cannot have both
halves from one source. 6.4.6 has the ioctl ABI the die's binary userspace
speaks - see GALCORE-SOURCE.md, where a 6.4.21 driver was built, loaded, and
wedged the hardware because 20 of 64 payload structs had changed. But 6.4.6
predates six mm and dma-buf changes and will not compile on 6.12. So the ABI
comes from 6.4.6 and the kernel glue has to be brought forward.

Every edit here is the form ST themselves use in 6.4.21, including their
LINUX_VERSION_CODE guard, so old kernels keep the old path and nothing is
invented. Each was found by building against 6.12 and reading the error, then
looking up how 6.4.21 writes the same line.
"""
import os
import re
import sys


def edit(path, subs, label):
    """Apply (pattern, replacement) pairs; report how many fired."""
    if not os.path.exists(path):
        print("    %-34s file absent, skipped" % label)
        return
    s = open(path, errors="replace").read()
    orig = s
    fired = 0
    for pat, rep in subs:
        s, n = re.subn(pat, rep, s, flags=re.S)
        fired += n
    if s == orig:
        print("    %-34s already current" % label)
    else:
        open(path, "w").write(s)
        print("    %-34s %d edit%s" % (label, fired, "" if fired == 1 else "s"))


def function_span(s, name):
    """(start, end) of a whole function definition.

    Starts at the return type line above the name and ends after the closing
    brace, which is found as the first line that is exactly "}" in column zero.

    Not brace matched: these functions contain #if/#else pairs where BOTH
    branches carry their own braces, so counting them never balances and the
    span comes out wrong - which produced an unterminated #else the first time
    this was tried. Kernel style always puts a function's closing brace in
    column zero, and nothing else in these files does.
    """
    i = s.find("\n" + name + "(")
    if i < 0:
        return None
    # walk back over the return type and any attributes, to the blank line
    start = s.rfind("\n\n", 0, i)
    start = 0 if start < 0 else start + 2
    j = s.find("\n}\n", i)
    if j < 0:
        return None
    return start, j + 3


def graft(target, reference, name, label):
    """Replace one whole function in target with the same one from reference.

    Used for kernel glue that was rewritten upstream rather than tweaked. The
    replacement carries ST's own LINUX_VERSION_CODE guards, so it still builds
    against the old kernels 6.4.6 was written for.
    """
    if not os.path.exists(reference):
        print("    %-34s no reference tree, skipped" % label)
        return
    tgt = open(target, errors="replace").read()
    ref = open(reference, errors="replace").read()
    a, b = function_span(tgt, name), function_span(ref, name)
    if not a or not b:
        print("    %-34s could not locate %s" % (label, name))
        return
    new = ref[b[0]:b[1]]
    if tgt[a[0]:a[1]] == new:
        print("    %-34s already grafted" % label)
        return
    open(target, "w").write(tgt[:a[0]] + new + tgt[a[1]:])
    print("    %-34s %d lines replaced with %d"
          % (label, tgt[a[0]:a[1]].count("\n"), new.count("\n")))


def main():
    if len(sys.argv) not in (2, 3):
        raise SystemExit(__doc__)
    g = sys.argv[1]
    ref = sys.argv[2] if len(sys.argv) == 3 else ""
    k = os.path.join(g, "hal/os/linux/kernel")
    a = os.path.join(k, "allocator/default")

    # kbuild dropped EXTRA_CFLAGS at 7.2 - scripts/Makefile.lib has no mention
    # of it any more. The ddk puts every -D and -I through it, so on 7.2 they
    # were all silently discarded and the build failed in a way that looks
    # nothing like the cause:
    #
    #   gc_hal_kernel_linux.h: No such file or directory
    #   'gcdENABLE_DRM' is not defined, evaluates to '0' [-Werror=undef]
    #
    # ccflags-y is the documented replacement and has been supported for many
    # years, so this is applied unconditionally rather than by version.
    n = 0
    for d, _, fs in os.walk(g):
        for f in fs:
            if f not in ("Kbuild", "Makefile", "makefile") and not f.endswith(".config"):
                continue
            p = os.path.join(d, f)
            try:
                t = open(p, errors="replace").read()
            except OSError:
                continue
            if "EXTRA_CFLAGS" not in t:
                continue
            open(p, "w").write(t.replace("EXTRA_CFLAGS", "ccflags-y"))
            n += 1
    print("    %-34s %s" % ("EXTRA_CFLAGS -> ccflags-y",
                            "%d files" % n if n else "already current"))

    # 6.5 dropped the vmas argument from get_user_pages(). 6.4.6 passes
    # "pages, NULL"; the NULL is vmas.
    edit(os.path.join(a, "gc_hal_kernel_allocator_user_memory.c"), [
        (r"(\n\s*)(pages,\s*\n\s*NULL\);)",
         r"\1#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 5, 0)"
         r"\1pages);"
         r"\1#else"
         r"\1\2"
         r"\1#endif"),
    ], "get_user_pages vmas")

    # 6.3 made vm_area_struct.vm_flags read-only; vm_flags_set() is the setter.
    for f in ("gc_hal_kernel_allocator_gfp.c", "gc_hal_kernel_allocator_reserved_mem.c"):
        edit(os.path.join(a, f), [
            (r"(\n(\s*))vma->vm_flags \|= gcdVM_FLAGS;",
             r"\1#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 3, 0)"
             r"\1vm_flags_set(vma, gcdVM_FLAGS);"
             r"\1#else"
             r"\1vma->vm_flags |= gcdVM_FLAGS;"
             r"\1#endif"),
        ], "vm_flags_set in " + f.split("_")[-1])

    # 6.4 renamed MAX_ORDER to MAX_PAGE_ORDER. 6.4.21 keeps the same
    # comparison, so the rename is all that is needed.
    edit(os.path.join(a, "gc_hal_kernel_allocator_gfp.c"), [
        (r"(\n(\s*))if \(order >= MAX_ORDER\)",
         r"\1#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 4, 0)"
         r"\1if (order >= MAX_PAGE_ORDER)"
         r"\1#else"
         r"\1if (order >= MAX_ORDER)"
         r"\1#endif"),
    ], "MAX_PAGE_ORDER rename")

    # in_irq() was removed; in_hardirq() is the name now.
    n = 0
    for d, _, fs in os.walk(os.path.join(g, "hal")):
        for f in fs:
            if not f.endswith((".c", ".h")):
                continue
            p = os.path.join(d, f)
            t = open(p, errors="replace").read()
            if "in_irq()" not in t:
                continue
            open(p, "w").write(t.replace("in_irq()", "in_hardirq()"))
            n += 1
    print("    %-34s %s" % ("in_irq -> in_hardirq",
                            "%d files" % n if n else "already current"))

    # nth_page() is gone from 7.2 altogether. It was deleted because on every
    # config that matters the page array is contiguous, so it was always just
    # pointer arithmetic - which is what this shim does. arm64 is
    # SPARSEMEM_VMEMMAP, so that holds here. It goes in the common header
    # because four files use it, not just the one that failed first.
    edit(os.path.join(k, "gc_hal_kernel_linux.h"), [
        (r"(#include \"gc_hal_kernel\.h\")",
         r"\1\n\n#ifndef nth_page\n"
         r"/* removed in 7.2; the page array is contiguous on arm64 */\n"
         r"#define nth_page(page, n) ((page) + (n))\n#endif"),
    ], "nth_page shim")

    # MODULE_IMPORT_NS took a bare token until 7.2 stringified it at the call
    # site instead: 6.12 has MODULE_INFO(import_ns, __stringify(ns)), 7.2 has
    # MODULE_INFO(import_ns, ns), so the argument has to be a string literal.
    edit(os.path.join(k, "gc_hal_kernel_driver.c"), [
        (r"MODULE_IMPORT_NS\((?!\")([A-Za-z_][A-Za-z_0-9]*)\)",
         r'MODULE_IMPORT_NS("\1")'),
    ], "MODULE_IMPORT_NS strings")

    # struct drm_driver lost its .date field. Nothing reads it and the vendor
    # value was a 2017 datestamp.
    edit(os.path.join(k, "gc_hal_kernel_drm.c"), [
        (r"\n\s*\.date\s*=\s*\"[0-9]*\",", ""),
    ], "drm_driver .date dropped")

    # drm_open_helper() now refuses any fops that does not declare
    # FOP_UNSIGNED_OFFSET:
    #
    #   WARNING: drivers/gpu/drm/drm_file.c:329 at drm_open_helper, rknn_server
    #     drm_open_helper / drm_open / drm_stub_open / chrdev_open
    #
    # and returns -EINVAL, so rknn_server's open of /dev/dri/card0 fails. This
    # is the other half of removing ".llseek = no_llseek" above: that idiom was
    # replaced by the fop_flags bit, and dropping the old one without adding the
    # new one leaves the fops declaring neither. Every drm fops helper in
    # mainline - DEFINE_DRM_GEM_FOPS, drm_accel.h, drm_gem_dma_helper.h - sets
    # exactly this.
    edit(os.path.join(k, "gc_hal_kernel_drm.c"), [
        (r"(static const struct file_operations viv_drm_fops = \{\n"
         r"\s*\.owner\s*=\s*THIS_MODULE,)",
         r"\1\n#if defined(FOP_UNSIGNED_OFFSET)\n"
         r"    .fop_flags          = FOP_UNSIGNED_OFFSET,\n"
         r"#endif"),
    ], "drm fops FOP_UNSIGNED_OFFSET")

    # linux/string.h, which the ddk never included and got by luck through
    # another header until 7.2 stopped pulling that in.
    edit(os.path.join(k, "gc_hal_kernel_linux.h"), [
        (r"(#ifndef nth_page)", r"#include <linux/string.h>\n\n\1"),
    ], "string.h include")

    # 7.2 removed strncpy outright - string.h now only names it in comments, as
    # the thing to stop using. Both call sites copy a name into a fixed buffer
    # and ignore the return value, which is exactly what strscpy is for, and it
    # guarantees the NUL termination strncpy did not.
    n = 0
    for d, _, fs in os.walk(os.path.join(g, "hal")):
        for f in fs:
            if not f.endswith(".c"):
                continue
            p = os.path.join(d, f)
            t = open(p, errors="replace").read()
            if "strncpy(" not in t:
                continue
            open(p, "w").write(re.sub(r"\bstrncpy\(", "strscpy(", t))
            n += 1
    print("    %-34s %s" % ("strncpy -> strscpy",
                            "%d files" % n if n else "already current"))

    # arm64's virt_addr_valid() takes a pointer as of 6.12, and 6.4.6 hands it
    # the unsigned long copy. 6.4.21 passes the gctPOINTER instead, which is
    # right on every version, so no guard is needed.
    edit(os.path.join(k, "gc_hal_kernel_os.c"), [
        (r"virt_addr_valid\(logical\)", "virt_addr_valid(Logical)"),
    ], "virt_addr_valid takes a pointer")

    # dma_resv_lock() lives in its own header, which 6.4.6 never included
    # because it never used it.
    edit(os.path.join(a, "gc_hal_kernel_allocator_dmabuf.c"), [
        (r"(#include <linux/dma-mapping\.h>)",
         r"\1\n#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 2, 0)\n"
         r"#include <linux/dma-resv.h>\n#endif"),
    ], "dma-resv.h include")

    # _QueryProcessPageTable walked the page tables by hand, and
    # pte_offset_map_lock() stopped being exported to modules after 6.5 -
    # everything compiles and then modpost fails on __pte_offset_map_lock.
    # There is no small fix: 6.4.21 replaced the whole user-VM branch with
    # follow_pfn / follow_pte / follow_pfnmap_start depending on the kernel.
    # Take their function whole. It is an internal os helper, so nothing about
    # the ioctl ABI moves with it, and their version guards keep the old walk
    # for old kernels.
    if ref:
        graft(os.path.join(k, "gc_hal_kernel_os.c"),
              os.path.join(ref, "hal/os/linux/kernel/gc_hal_kernel_os.c"),
              "_QueryProcessPageTable", "_QueryProcessPageTable")
        # the grafted code tests gcdUSING_PFN_FOLLOW, which is a 6.4.21 config
        # knob 6.4.6 has never heard of. The kernel builds with -Werror=undef,
        # so it has to exist even though the version test beside it is what
        # actually selects the path.
        edit(os.path.join(k, "gc_hal_kernel_os.c"), [
            (r"(#include \"gc_hal_kernel_linux\.h\")",
             r"\1\n\n#ifndef gcdUSING_PFN_FOLLOW\n"
             r"/* a 6.4.21 knob; the LINUX_VERSION_CODE test selects the path */\n"
             r"#define gcdUSING_PFN_FOLLOW 0\n#endif"),
        ], "gcdUSING_PFN_FOLLOW defined")

    # import_pfn_map() walks the page tables too, and it is the other user of
    # pte_offset_map_lock(). It cannot be grafted the way
    # _QueryProcessPageTable was, because 6.4.21 changed its argument list:
    #
    #   6.4.6   import_pfn_map(gckOS Os, struct um_desc *um, ...)
    #   6.4.21  import_pfn_map(gckOS Os, struct device *dev, struct um_desc *um,
    #                          unsigned long addr, size_t pfn_count)
    #
    # so the 6.12 path is written into 6.4.6's own loop instead, following
    # 6.4.21's shape. Two things differ from a naive transcription:
    #
    #  - follow_pfnmap_start() must be called with the mmap lock held. 6.4.6
    #    drops it immediately after find_vma(), so the lock is taken again
    #    around the loop and released on every exit from it.
    #  - 6.4.21's retry through gckOS_ReadMappedPointer() is left out. It needs
    #    a variable 6.4.6's function does not have, and it only converts one
    #    failure mode into another for an address the caller should not have
    #    passed. Failing is what 6.4.6 already does on a bad walk.
    edit(os.path.join(a, "gc_hal_kernel_allocator_user_memory.c"), [
        (r"(\n)(    for \(i = 0; i < pfn_count; i\+\+\)\n    \{\n)"
         r"(        spinlock_t \*ptl;)",
         r"\1#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 12, 0)\n"
         r"    /* follow_pfnmap_start() wants the mmap lock held */\n"
         r"    down_read(&current_mm_mmap_sem);\n"
         r"#endif\n"
         r"\2"
         r"#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 12, 0)\n"
         r"        struct follow_pfnmap_args args = { .vma = vma, .address = addr };\n"
         r"\n"
         r"        if (follow_pfnmap_start(&args))\n"
         r"        {\n"
         r"            up_read(&current_mm_mmap_sem);\n"
         r"            goto err;\n"
         r"        }\n"
         r"\n"
         r"        pfns[i] = args.pfn;\n"
         r"        follow_pfnmap_end(&args);\n"
         r"#else\n"
         r"\3"),

        (r"(\n        pfns\[i\] = pte_pfn\(\*pte\);\n"
         r"        pte_unmap_unlock\(pte, ptl\);\n)"
         r"(\n        /\* Advance to next\. \*/\n"
         r"        addr \+= PAGE_SIZE;\n    \}\n)",
         r"\1#endif\n"
         r"\2"
         r"#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 12, 0)\n"
         r"    up_read(&current_mm_mmap_sem);\n"
         r"#endif\n"),
    ], "import_pfn_map follow_pfnmap")

    # 6.2 moved dma_buf locking onto the reservation object.
    edit(os.path.join(a, "gc_hal_kernel_allocator_dmabuf.c"), [
        (r"(\n(\s*))ret = mutex_lock_interruptible\(&buf_obj->lock\);",
         r"\1#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 2, 0)"
         r"\1ret = dma_resv_lock_interruptible(buf_obj->resv, NULL);"
         r"\1#else"
         r"\1ret = mutex_lock_interruptible(&buf_obj->lock);"
         r"\1#endif"),
        (r"(\n(\s*))mutex_unlock\(&buf_obj->lock\);",
         r"\1#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 2, 0)"
         r"\1dma_resv_unlock(buf_obj->resv);"
         r"\1#else"
         r"\1mutex_unlock(&buf_obj->lock);"
         r"\1#endif"),
    ], "dma_resv locking")


if __name__ == "__main__":
    main()
