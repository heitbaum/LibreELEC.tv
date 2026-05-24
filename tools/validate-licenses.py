#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2026-present Team LibreELEC (https://libreelec.tv)
"""
Validate PKG_LICENSE fields against source tarballs.

Run from the repo root: tools/validate-licenses.py [-o output.csv]

Reads every packages/**/package.mk, locates the corresponding source tarball
under sources/, and classifies the declared PKG_LICENSE as:

  correct - 100%              confirmed by SPDX file headers or text fingerprint
  correct - <100%             high-confidence match with minor caveats
  believe correct - NN%       plausible but not fully verifiable from tarball alone
  incorrect - <reason>        evidence contradicts the declared licence
  no-source - <reason>        meta/virtual package with no downloadable source
  missing-tarball             tarball not present in sources/
  tarball-error - <reason>    tarball could not be opened/read

Output columns: pkg_name, pkg_license, status, evidence, pkg_path
"""

import argparse
import csv
import os
import re
import sys
import tarfile
import zipfile
from pathlib import Path

REPO    = Path.cwd()
SOURCES = REPO / "sources"
LICDIR  = REPO / "licenses"

# ── Hard-coded overrides / lookup tables ──────────────────────────────────────

# Packages whose source tarball lives under a *different* package name in sources/.
# The declared PKG_LICENSE is validated against that other package's source.
SOURCE_FROM = {
    # mesa-reusable is a pre-built binary extracted from mesa source;
    # its declared licence is verified via mesa's source tree.
    "mesa-reusable": "mesa",
}

# Packages where SPDX-License-Identifier headers inside source files are
# unreliable for the purpose of validating the *package* licence, because
# the tarball also contains:
#   - kernel / syscall-interface headers (GPL, irrelevant to userspace library)
#   - CLI tools with a stricter licence than the library itself
#   - Bundled third-party components with different licences
#   - Test / example files with unrelated licences
#
# For these packages the script falls back to COPYING/LICENSE text analysis
# and ignores per-file SPDX headers entirely.
SKIP_SPDX_HEADERS = {
    "libdrm",       # kernel/DRM headers (GPL) sit beside MIT library
    "libinput",     # GPL test tools sit beside MIT library
    "xxHash",       # cli/ subdir is GPL-2.0-only; xxhash.h library is BSD-2-Clause
    "gstreamer",    # BSD-3-Clause in test/plugin files; core is LGPL-2.1-or-later
    "libnpth",      # CC0 in test files; library is LGPL-2.1-or-later
    "oscam",        # Apache-2.0 in bundled cJSON; main code is GPL-3.0-only
    "rsyslog",      # Apache-2.0 in optional modules; core is GPL-3.0-or-later
    "alsa-utils",   # BSD-3-Clause in bundled lib; tools are GPL-2.0-or-later
    "nmap",         # bundled components (BSD/MIT/etc.); Nmap itself is LicenseRef-Nmap
    "gcc",          # MIT in libiberty test files; GCC is GPL-3.0-or-later
    "lirc",         # include/media/lirc.h is a kernel syscall header (GPL WITH note)
    "nfs-utils",    # kernel syscall headers in tree; tools are GPL-2.0-or-later
    "keyutils",     # kernel syscall headers in tree
    "libftdi1",     # tools/ is GPL-2.0; library is LGPL-2.0-only
    "fuse3",        # kernel module is GPL-2.0; userspace lib is LGPL-2.1-only
    "libaio",       # src/syscall-generic.h is a kernel header (GPL-2.0 WITH Linux-syscall-note).
                    # COPYING bundles the LGPL-2.1 text as reference but all 14 src/*.c|h grant
                    # "version 2 of the License" → LGPL-2.0-or-later (see LICENCE_CONFIRMED)
    "nftables",     # COPYING: original code GPL-2.0-only; new contributions GPL-2.0-or-later.
                    # declared GPL-2.0-only is correct for the combined work.
    "bluez",        # LGPL library (libbluetooth) has more source files than GPL tools; by-count
                    # LGPL-2.1-or-later dominates but COPYING + GPL tools are the primary licence
    "libksba",      # main library headers: LGPL-3.0-or-later OR GPL-2.0-or-later; autoconf
                    # helpers are LGPL-2.1-or-later + FSFUL and pollute the first-60-files scan
    "strace",       # tarball begins with tests-mx32/ and tests/ (GPL-2.0-or-later), so the
                    # first-60-files scan returns all-GPL.  COPYING is explicit:
                    # strace itself is LGPL-2.1-or-later; test suite is GPL-2.0-or-later.
                    # 375 of 379 src/*.c|h are LGPL-2.1-or-later; the 4 GPL files are
                    # disable_ptrace_*.c test-helper executables, not the installed binary.
}

# Packages whose project-level SPDX headers have been verified INCORRECT
# by reading the COPYING/LICENSE file directly.  The COPYING text is
# authoritative; SPDX headers from source files are discarded.
SPDX_HEADERS_INCORRECT = {
    # COPYING says "distribute, and sell" = HPND-sell-variant.
    # The project mistakenly uses HPND in its per-file SPDX tags.
    "fontconfig",
}

# Packages where BOTH SPDX headers AND the COPYING file give misleading results
# and the correct licence has been established by reading the version-grant text
# in the source files themselves (e.g. "version 2 of the License, or any later
# version" in comment blocks, which is the operative grant regardless of which
# licence deed is bundled as COPYING).
#
# classify() short-circuits to "correct - 100%" when the declared licence matches
# the confirmed value, or "incorrect" when it does not.
LICENCE_CONFIRMED = {
    # COPYING bundles LGPL-2.1 text (newer deed used as reference), but all 14
    # src/*.c|h grant "version 2 of the License, or (at your option) any later
    # version" = LGPL-2.0-or-later.  The one LGPL-2.1+ SPDX tag in the tree is
    # from harness/cases/23.t (a test file), not a library source file.
    "libaio": "LGPL-2.0-or-later",
    # COPYING is the old "GNU Library GPL Version 2" deed (= LGPL-2.0).
    # All 26 atk/*.c grant "version 2 of the License, or any later version"
    # = LGPL-2.0-or-later.  meson.build metadata says 'LGPL-2.1-or-later' and
    # .gitlab-ci/meson-junit-report.py has an LGPL-2.1-or-later SPDX tag, but
    # neither is an operative grant on the library source code.
    "atk": "LGPL-2.0-or-later",
    # COPYING is LGPL-2.1.  70x SPDX headers saying LGPL-2.0-or-later appear
    # only in shell scripts, .spec and test runner files — NOT library .c/.h.
    # The library itself is mixed: 51 of 54 libexif/*.c|h grant "version 2 of
    # the License" (LGPL-2.0-or-later), but exif-ifd.c, exif-ifd.h, and
    # exif-mnote-data.c explicitly grant "version 2.1 of the License, or any
    # later version".  Because those 3 files cannot be distributed under
    # LGPL-2.0-only, the correct minimum for the combined work is LGPL-2.1-or-later.
    "libexif": "LGPL-2.1-or-later",
    # COPYING is the plain GPL-2.0 deed text, which is ambiguous about "only"
    # vs "or-later".  All 23 .c/.h source files and 4 test scripts carry
    # explicit SPDX GPL-2.0-or-later tags — zero GPL-2.0-only files anywhere.
    "exfatprogs": "GPL-2.0-or-later",
    # LICENSE documents three components:
    #   (1) glad source code (Python + Jinja2 templates): MIT
    #   (2) Khronos spec files (gl.xml, egl.xml, glx.xml, wgl.xml, vk_platform.h,
    #       vulkan_video_*.h, eglplatform.h): Apache-2.0; vk.xml: Apache-2.0 OR MIT
    #   (3) khrplatform.h: old Khronos "Materials" grant — MIT-equivalent, no SPDX tag
    # base_template.c/h carry SPDX (WTFPL OR CC0-1.0) AND Apache-2.0 but that tag
    # is the license for the generated output, not the template file (which is MIT
    # as part of the glad source code).  pyproject.toml: MIT :: OSI Approved.
    "glad": "MIT AND Apache-2.0",
    # lib/ and programs/ prose: "both the BSD-style license (LICENSE) and the GPLv2
    # (COPYING). You may select, at your option, one of the above-listed licenses."
    # COPYING = bare GPL-2.0 deed (no 'or later' in operative terms); 87/89 lib/*.c|h
    # and all 25 programs/*.c|h carry this dual-licence prose → GPL-2.0-only.
    # contrib/linux-kernel/ carries SPDX GPL-2.0+ (kernel-submission requirement only,
    # not part of the installed library or CLI) — that is what the SPDX scan finds.
    "zstd": "GPL-2.0-only OR BSD-3-Clause",
}

# ── package.mk parsing ────────────────────────────────────────────────────────

def parse_mk(path):
    """Return dict of PKG_* values (double-quoted values only)."""
    vals = {}
    text = Path(path).read_text(errors="replace")
    for m in re.finditer(r'^(PKG_\w+)="([^"]*)"', text, re.MULTILINE):
        vals[m.group(1)] = m.group(2)
    return vals

# ── tarball location ──────────────────────────────────────────────────────────

TARBALL_EXTS = [
    ".tar.gz", ".tar.xz", ".tar.bz2", ".tgz",
    ".tar.lz", ".tar.lzma", ".tar.zst", ".zip",
]

# Source-file extensions that are NOT tarballs and cannot be scanned for licence
# headers.  Detected via the PKG_URL basename so no explicit per-package list is
# needed.
NON_TARBALL_EXTS = frozenset([
    ".bin",   # binary self-extracting installer
    ".run",   # self-extracting installer (NVIDIA, etc.)
    ".c",     # single-file C source (nmon)
    ".exe",   # Windows executable / self-extractor
    ".sh",    # shell self-extractor
    ".img",   # disk/firmware image
])

def find_tarball(pkg_name, pkg_version, pkg_source_name=None, _source_from=SOURCE_FROM):
    """Return (Path, version_matched) to the source tarball, or (None, False).
    Uses PKG_SOURCE_NAME as the exact filename when it is a literal (no shell
    expansion).  Otherwise looks for sources/<pkg_name>/<pkg_name>-<pkg_ver>.<ext>.
    No fallback to unversioned or version-mismatched tarballs.
    Redirects to another package's source directory when SOURCE_FROM applies."""
    if pkg_name in _source_from:
        pkg_dir = SOURCES / _source_from[pkg_name]
    else:
        pkg_dir = SOURCES / pkg_name
    if not pkg_dir.is_dir():
        return None, False

    # Explicit source filename (literal PKG_SOURCE_NAME, no shell expansion)
    if pkg_source_name and "$" not in pkg_source_name:
        p = pkg_dir / pkg_source_name
        return (p, True) if p.exists() else (None, False)

    # Standard pattern: pkgname-pkgver.ext
    if pkg_version and not pkg_version.startswith("$("):
        for ext in TARBALL_EXTS:
            p = pkg_dir / f"{pkg_name}-{pkg_version}{ext}"
            if p.exists():
                return p, True
        # Version-prefixed (e.g. commit hash appended to name)
        for f in sorted(pkg_dir.iterdir()):
            if (f.name.startswith(f"{pkg_name}-{pkg_version}")
                    and not f.name.endswith((".sha256", ".url", ".sig", ".asc"))):
                return f, True

    return None, False

# ── tarball reading ───────────────────────────────────────────────────────────

LICENSE_BASENAMES = {
    "copying", "copying.lib", "copying.lesser", "copying.gpl",
    "license", "license.txt", "license.md", "license.rst",
    "licence", "licence.txt", "licence.md",
    "copyright", "copyright.txt",
    "notice", "notice.txt",
}

SRC_EXTS = {".c", ".h", ".cxx", ".cpp", ".cc", ".hxx",
            ".py", ".go", ".rs", ".java", ".js", ".ts", ".rb"}

MAX_LICENSE_BYTES = 32768   # 32 KB per license file
MAX_SRC_HEADER_BYTES = 1024 # first 1 KB of source file
MAX_SRC_FILES = 60          # max source files to scan for SPDX headers
MAX_SRC_DEPTH = 4           # don't descend too deep

def _inner_path(member_name):
    """Strip the top-level directory component from a tar member path."""
    parts = member_name.replace("\\", "/").split("/")
    if len(parts) > 1:
        return "/".join(parts[1:]), parts[1:]
    return parts[0], parts

def read_tarball(tarball_path):
    """
    Open tarball and collect:
      license_texts : {rel_path: text}  — COPYING/LICENSE/LICENSES/* content
      spdx_headers  : [(rel_path, spdx_expr)] — SPDX-License-Identifier lines
    Returns (license_texts, spdx_headers, error_str_or_None)
    """
    license_texts = {}
    spdx_headers  = []
    src_checked   = 0

    try:
        if tarball_path.name.endswith(".zip"):
            return _read_zip(tarball_path)
        tf = tarfile.open(str(tarball_path), "r:*")
    except Exception as e:
        return {}, [], f"open error: {e}"

    try:
        members = tf.getmembers()
    except Exception as e:
        tf.close()
        return {}, [], f"list error: {e}"

    for member in members:
        if not member.isfile():
            continue

        inner, parts = _inner_path(member.name)
        basename     = (parts[-1] if parts else "").lower()
        depth        = len(parts)

        # Skip Debian packaging metadata — debian/copyright uses DEP-5 format
        # and may describe "or later" grants that do not reflect upstream intent.
        if len(parts) >= 2 and parts[0].lower() == "debian":
            continue

        in_licenses_dir = (depth >= 2 and parts[0].lower() == "licenses")
        is_top_license  = (depth == 1 and basename in LICENSE_BASENAMES)
        is_nested_license = (depth == 2 and basename in LICENSE_BASENAMES)

        if is_top_license or in_licenses_dir or is_nested_license:
            try:
                f = tf.extractfile(member)
                if f:
                    text = f.read(MAX_LICENSE_BYTES).decode(errors="replace")
                    license_texts[inner] = text
            except Exception:
                pass

        elif src_checked < MAX_SRC_FILES and depth <= MAX_SRC_DEPTH:
            _, ext = os.path.splitext(basename)
            if ext in SRC_EXTS:
                try:
                    f = tf.extractfile(member)
                    if f:
                        header = f.read(MAX_SRC_HEADER_BYTES).decode(errors="replace")
                        m = re.search(
                            r"SPDX-License-Identifier:\s*([^\r\n*/]+)", header
                        )
                        if m:
                            spdx_id = m.group(1).strip().rstrip("*/# \t")
                            spdx_headers.append((inner, spdx_id))
                    src_checked += 1
                except Exception:
                    pass

    tf.close()
    return license_texts, spdx_headers, None


def _read_zip(path):
    license_texts = {}
    spdx_headers  = []
    src_checked   = 0
    try:
        with zipfile.ZipFile(str(path), "r") as zf:
            for name in zf.namelist():
                parts = name.replace("\\", "/").split("/")
                inner = "/".join(parts[1:]) if len(parts) > 1 else parts[0]
                basename = parts[-1].lower() if parts else ""
                depth = len(parts) - 1

                in_licenses_dir = (depth >= 2 and parts[1].lower() == "licenses")
                is_top_license  = (depth == 1 and basename in LICENSE_BASENAMES)

                if is_top_license or in_licenses_dir:
                    try:
                        with zf.open(name) as f:
                            text = f.read(MAX_LICENSE_BYTES).decode(errors="replace")
                            license_texts[inner] = text
                    except Exception:
                        pass

                elif src_checked < MAX_SRC_FILES and depth <= MAX_SRC_DEPTH:
                    _, ext = os.path.splitext(basename)
                    if ext in SRC_EXTS:
                        try:
                            with zf.open(name) as f:
                                header = f.read(MAX_SRC_HEADER_BYTES).decode(errors="replace")
                                m = re.search(
                                    r"SPDX-License-Identifier:\s*([^\r\n*/]+)", header
                                )
                                if m:
                                    spdx_headers.append(
                                        (inner, m.group(1).strip().rstrip("*/# \t"))
                                    )
                            src_checked += 1
                        except Exception:
                            pass
    except Exception as e:
        return {}, [], f"zip error: {e}"
    return license_texts, spdx_headers, None

# ── SPDX expression helpers ───────────────────────────────────────────────────

_SPDX_TOKEN_RE = re.compile(
    r'\(|\)|\bAND\b|\bOR\b|\bWITH\b|[A-Za-z0-9][A-Za-z0-9\-_\+\.]*',
    re.IGNORECASE
)

def parse_spdx_components(expr):
    """Return list of individual license IDs from an SPDX expression."""
    ids = []
    skip_next = False
    for tok in _SPDX_TOKEN_RE.findall(expr):
        if tok.upper() in ("AND", "OR", "(", ")"):
            skip_next = False
        elif tok.upper() == "WITH":
            skip_next = True
        elif skip_next:
            skip_next = False
        else:
            ids.append(tok)
    return ids

def normalise_id(spdx_id):
    """Lower-case, collapse whitespace."""
    return spdx_id.strip().lower()

_SPDX_NORM = {
    "gpl-2.0":       "GPL-2.0-only",
    "gpl-2.0+":      "GPL-2.0-or-later",
    "gpl-3.0":       "GPL-3.0-only",
    "gpl-3.0+":      "GPL-3.0-or-later",
    "lgpl-2.0":      "LGPL-2.0-only",
    "lgpl-2.0+":     "LGPL-2.0-or-later",
    "lgpl-2.1":      "LGPL-2.1-only",
    "lgpl-2.1+":     "LGPL-2.1-or-later",
    "lgpl-3.0":      "LGPL-3.0-only",
    "lgpl-3.0+":     "LGPL-3.0-or-later",
    "agpl-3.0":      "AGPL-3.0-only",
    "agpl-3.0+":     "AGPL-3.0-or-later",
    "gpl-2.1-or-later": "LGPL-2.1-or-later",
}

_SYSCALL_NOTE_RE = re.compile(r'\s+WITH\s+Linux-syscall-note', re.IGNORECASE)
_PAREN_RE = re.compile(r'[()]')

def normalise_spdx_expr(expr):
    """
    Normalise a raw SPDX expression for comparison:
    - strip WITH Linux-syscall-note
    - convert deprecated bare/+ forms to -only/-or-later
    - strip parentheses
    """
    expr = _SYSCALL_NOTE_RE.sub("", expr)
    expr = _PAREN_RE.sub("", expr)
    tokens = _SPDX_TOKEN_RE.findall(expr)
    out = []
    for tok in tokens:
        low = tok.lower()
        if low in _SPDX_NORM:
            out.append(_SPDX_NORM[low])
        else:
            out.append(tok)
    return " ".join(out)

def _is_full_gpl_template(text):
    """
    Return True when the text IS the standard GPL/LGPL boilerplate distribution
    (the actual license deed, >3 KB, containing the FSF preamble).
    The template contains 'any later version' in the How-To-Apply appendix,
    which must NOT be used to infer a project's own -or-later grant.
    """
    return (
        len(text) > 3000 and
        bool(re.search(
            r"freedom to (use|copy|share|modify|distribute|change).{0,80}free software",
            text, re.IGNORECASE | re.DOTALL
        ))
    )

# ── License text fingerprints ─────────────────────────────────────────────────

FINGERPRINTS = [
    (r"GNU GENERAL PUBLIC LICENSE\s+Version 3",           "GPL-3.0"),
    (r"GNU GENERAL PUBLIC LICENSE\s+Version 2",           "GPL-2.0"),
    (r"version 2 of the GNU General Public License",      "GPL-2.0"),
    (r"GNU General Public License as published.*?version 2", "GPL-2.0"),
    (r"GNU LESSER GENERAL PUBLIC LICENSE\s+Version 3",    "LGPL-3.0"),
    (r"GNU LESSER GENERAL PUBLIC LICENSE\s+Version 2\.1", "LGPL-2.1"),
    (r"GNU Lesser General Public License.*?version 2\.1", "LGPL-2.1"),
    (r"GNU LESSER GENERAL PUBLIC LICENSE\s+Version 2\b",  "LGPL-2.0"),
    (r"GNU LIBRARY GENERAL PUBLIC LICENSE\s+Version 2",   "LGPL-2.0"),
    (r"GNU Library General Public License.*?version 2\b", "LGPL-2.0"),
    (r"Apache License[,\s]+Version 2\.0",                 "Apache-2.0"),
    (r"Mozilla Public License.*?Version 2\.0",            "MPL-2.0"),
    (r"Mozilla Public License.*?Version 1\.1",            "MPL-1.1"),
    (r"Boost Software License.*?Version 1\.0",            "BSL-1.0"),
    (r"This software is provided 'as-is'",                "Zlib"),
    (r'software is provided "as is" without',             "Zlib"),
    (r"SIL OPEN FONT LICENSE",                            "OFL-1.1"),
    (r"This is free and unencumbered software released into the public domain", "Unlicense"),
    (r"Permission to use, copy, modify, distribute, and sell", "HPND-sell-variant"),
    (r"Permission to use, copy, modify,? and/or distribute",   "ISC"),
    (r"Permission to use, copy, modify,? and distribute",      "HPND"),
    (r"Permission is hereby granted, free of charge",          "MIT"),
    (r"Redistribution and use in source and binary forms",     "BSD"),
    (r"may you do good and not evil",                          "blessing"),
    (r"remain in the source code as-is\.\s*Mark Lord",        "hdparm"),
    (r"PNG Reference Library License version 2",              "libpng-2.0"),
    (r"Sam Leffler.*Silicon Graphics",                        "libtiff"),
    (r"bzip2 and libbzip2",                                   "bzip2-1.0.6"),
    (r"X Consortium",                                          "X11"),
    (r"Carnegie.Mellon University|CMU",                       "MIT-CMU"),
    (r"UNICODE, INC\. LICENSE AGREEMENT|Unicode License",     "Unicode-3.0"),
    (r"Independent JPEG Group",                               "IJG"),
    (r"[Pp]ublic [Dd]omain",                                  "LicenseRef-PublicDomain"),
]

def _or_later_in(text, skip_if_template=True):
    if skip_if_template and _is_full_gpl_template(text):
        return False
    return bool(re.search(
        r"any later version|or[\s(]+at your option[\s)]+any later|or-later",
        text, re.IGNORECASE
    ))

def _only_explicit_in(text):
    return bool(re.search(r"version \d+\s+only\b|only version \d+", text, re.IGNORECASE))

def _bsd_clause_count(text):
    n = len(re.findall(r"\(\d\)", text))
    if n in (2, 3, 4):
        return n
    advert   = bool(re.search(r"advertising materials", text, re.IGNORECASE))
    endorses = bool(re.search(r"endorse or promote", text, re.IGNORECASE))
    return 4 if advert else (3 if endorses else 2)

def _mit_variant(text):
    if re.search(r"X Consortium", text, re.IGNORECASE):
        return "X11"
    if re.search(r"Carnegie.Mellon|CMU", text, re.IGNORECASE):
        return "MIT-CMU"
    return "MIT"

def identify_text_licenses(text):
    """Return list of (spdx_id, confidence_pct, note) from a license text blob."""
    results = []
    seen    = set()

    for pattern, base_id in FINGERPRINTS:
        if not re.search(pattern, text, re.IGNORECASE | re.DOTALL):
            continue

        spdx_id = base_id
        conf    = 85
        note    = f"text matches '{base_id}' pattern"

        if base_id in ("GPL-2.0", "GPL-3.0", "LGPL-2.0", "LGPL-2.1", "LGPL-3.0"):
            if _or_later_in(text):
                spdx_id = base_id + "-or-later"
                conf    = 92
                note    = f"COPYING matches {base_id}; 'any later version' clause present"
            elif _only_explicit_in(text):
                spdx_id = base_id + "-only"
                conf    = 92
                note    = f"COPYING matches {base_id}; 'version X only' clause present"
            else:
                for suffix in ("-only", "-or-later"):
                    sid = base_id + suffix
                    if sid not in seen:
                        seen.add(sid)
                        results.append((
                            sid, 70,
                            f"COPYING matches {base_id}; -only/-or-later not determinable "
                            f"from COPYING text alone (no 'any later version' and no 'only')"
                        ))
                continue

        elif base_id == "BSD":
            n       = _bsd_clause_count(text)
            spdx_id = f"BSD-{n}-Clause"
            conf    = 82
            note    = f"BSD {n}-clause redistribution text"

        elif base_id == "MIT":
            spdx_id = _mit_variant(text)
            conf    = 85 if spdx_id == "MIT" else 90
            note    = f"MIT-family permission text → {spdx_id}"

        elif base_id == "HPND":
            if re.search(r"distribute, and sell", text, re.IGNORECASE):
                spdx_id = "HPND-sell-variant"
                conf    = 90
                note    = "HPND text with 'distribute, and sell'"
            else:
                conf    = 88
                note    = "HPND text (no 'sell')"

        elif base_id in ("blessing", "hdparm", "libpng-2.0", "libtiff",
                         "bzip2-1.0.6", "ISC", "X11", "MIT-CMU",
                         "BSL-1.0", "Zlib", "OFL-1.1", "Unlicense",
                         "Apache-2.0", "MPL-2.0", "MPL-1.1",
                         "Unicode-3.0", "IJG", "HPND-sell-variant"):
            conf  = 93
            note  = f"{base_id} text fingerprint matched"

        elif base_id == "LicenseRef-PublicDomain":
            conf  = 75
            note  = "public domain language found"

        if spdx_id not in seen:
            seen.add(spdx_id)
            results.append((spdx_id, conf, note))

    return results

# ── SPDX header consensus ─────────────────────────────────────────────────────

def analyse_spdx_headers(headers):
    """Return (consensus_expr, confidence, note) from a list of (path, spdx_expr)."""
    if not headers:
        return None, 0, "no SPDX-License-Identifier found in source files"

    counts = {}
    for _, expr in headers:
        expr = normalise_spdx_expr(expr.strip())
        counts[expr] = counts.get(expr, 0) + 1

    total = sum(counts.values())

    if len(counts) == 1:
        expr = next(iter(counts))
        return expr, 99, f"SPDX header identical across all {total} scanned source file(s)"

    dominant = max(counts, key=counts.get)
    dom_n    = counts[dominant]
    ratio    = dom_n / total

    if ratio >= 0.9:
        return (dominant, 97,
                f"SPDX header dominant ({dom_n}/{total} files): {dominant}")

    if ratio >= 0.7:
        return (dominant, 90,
                f"SPDX header majority ({dom_n}/{total} files): {dominant}; "
                f"others: {[k for k in counts if k != dominant]}")

    unique  = sorted(counts.keys())
    combined = " AND ".join(unique)
    return (combined, 80, f"Multiple SPDX headers: {counts}")

# ── LicenseRef matching ───────────────────────────────────────────────────────

_licref_cache = {}

def _load_licref(licref_id):
    """Return text of licenses/<licref_id>.txt, or None."""
    if licref_id in _licref_cache:
        return _licref_cache[licref_id]
    p = LICDIR / f"{licref_id}.txt"
    if p.exists():
        text = p.read_text(errors="replace")
        _licref_cache[licref_id] = text
        return text
    _licref_cache[licref_id] = None
    return None

def match_licref_in_tarball(licref_id, license_texts):
    """Check whether the tarball contains the key text from our licenses/<id>.txt."""
    ref_text = _load_licref(licref_id)
    if ref_text is None:
        return False, f"no {licref_id}.txt in licenses/"

    sig_lines = [l.strip() for l in ref_text.splitlines()
                 if l.strip() and not l.startswith("#")][:3]

    for fname, text in license_texts.items():
        for line in sig_lines:
            if len(line) > 20 and line.lower() in text.lower():
                return True, f"LicenseRef text found in {fname}"

    return False, f"LicenseRef text NOT found in tarball (checked {list(license_texts.keys())})"

# ── Main classification logic ─────────────────────────────────────────────────

def classify(pkg_name, pkg_license, license_texts, spdx_headers):
    """Returns (status_string, evidence_string)."""
    declared = parse_spdx_components(pkg_license)

    # ── LICENCE_CONFIRMED short-circuit ──────────────────────────────────
    # For packages where automated evidence (SPDX headers + COPYING text) is
    # both unreliable, the correct licence was established by reading the
    # version-grant text in source files directly.
    if pkg_name in LICENCE_CONFIRMED:
        confirmed = LICENCE_CONFIRMED[pkg_name]
        if normalise_id(normalise_spdx_expr(pkg_license)) == normalise_id(normalise_spdx_expr(confirmed)):
            return ("correct - 100%",
                    f"manually confirmed from source grant text: {confirmed} "
                    f"(see LICENCE_CONFIRMED table)")
        return (f"incorrect - declared '{pkg_license}', confirmed '{confirmed}'",
                "see LICENCE_CONFIRMED table")

    if pkg_name in SKIP_SPDX_HEADERS:
        spdx_headers = []
    if pkg_name in SPDX_HEADERS_INCORRECT:
        spdx_headers = []

    if spdx_headers:
        h_expr, h_conf, h_note = analyse_spdx_headers(spdx_headers)
        if h_expr:
            h_norm  = normalise_spdx_expr(h_expr)
            d_norm  = normalise_spdx_expr(pkg_license)
            h_components = {normalise_id(c) for c in parse_spdx_components(h_norm)}
            d_components = {normalise_id(c) for c in parse_spdx_components(d_norm)}

            if d_components == h_components:
                pct = h_conf
                label = "correct - 100%" if pct >= 99 else f"correct - {pct}%"
                return label, f"SPDX headers match exactly: {h_expr} | {h_note}"

            if d_components.issubset(h_components):
                diff = h_components - d_components
                return (f"believe correct - {h_conf - 5}% - "
                        f"declared is subset of SPDX headers (extra: {diff})",
                        f"declared={pkg_license}; headers={h_expr}")

            if h_components.issubset(d_components):
                missing = d_components - h_components
                return (f"believe correct - {h_conf - 10}% - "
                        f"SPDX headers only confirmed {h_components}; "
                        f"declared also has {missing} (may be in unscanned files)",
                        h_note)

            return (f"incorrect - SPDX headers say '{h_expr}', declared '{pkg_license}'",
                    h_note)

    if not license_texts:
        return ("believe correct - 40% - no license files or SPDX headers found in tarball",
                "tarball scanned; nothing recognisable found")

    all_found = []
    for fname, text in sorted(license_texts.items()):
        for spdx_id, conf, note in identify_text_licenses(text):
            all_found.append((spdx_id, conf, note, fname))

    if not all_found:
        return (f"believe correct - 45% - license files present but text unrecognised",
                f"files checked: {list(license_texts.keys())}")

    found_ids = {normalise_id(x[0]): x for x in all_found}

    src_or_later = any(
        "or-later" in expr.lower() or "gpl-2.0+" in expr.lower() or "gpl-3.0+" in expr.lower()
        for _, expr in spdx_headers
    )
    src_only = any("-only" in expr.lower() for _, expr in spdx_headers)

    resolved = {}
    for sid_low, (spdx_id, conf, note, fname) in list(found_ids.items()):
        if conf == 70 and ("-only" in spdx_id or "-or-later" in spdx_id):
            if src_or_later and spdx_id.endswith("-or-later"):
                resolved[sid_low] = (spdx_id, 88,
                    note + "; confirmed by SPDX header in source", fname)
            elif src_only and spdx_id.endswith("-only"):
                resolved[sid_low] = (spdx_id, 88,
                    note + "; confirmed by SPDX header in source", fname)
    found_ids.update(resolved)

    component_results = []

    for decl_id in declared:
        decl_low  = normalise_id(decl_id)
        decl_base = re.sub(r"-(only|or-later)$", "", decl_low)

        if decl_id.startswith("LicenseRef-"):
            match, note = match_licref_in_tarball(decl_id, license_texts)
            if match:
                component_results.append((decl_id, "match", 90, note))
            else:
                component_results.append((decl_id, "unverified", 60, note))
            continue

        if decl_low in found_ids:
            entry = found_ids[decl_low]
            component_results.append((decl_id, "match", entry[1], entry[2]))
            continue

        family = [(sid, data) for sid, data in found_ids.items()
                  if re.sub(r"-(only|or-later)$", "", sid) == decl_base]

        if family:
            best_sid, best_data = max(family, key=lambda x: x[1][1])
            decl_or_later  = decl_low.endswith("-or-later")
            decl_only      = decl_low.endswith("-only")
            found_or_later = best_sid.endswith("-or-later")
            found_only     = best_sid.endswith("-only")

            if decl_or_later and found_only:
                component_results.append((decl_id, "mismatch", best_data[1],
                    f"declared -or-later but source evidence says -only: {best_data[2]}"))
            elif decl_only and found_or_later:
                component_results.append((decl_id, "mismatch", best_data[1],
                    f"declared -only but source evidence says -or-later: {best_data[2]}"))
            elif best_data[1] == 70:
                component_results.append((decl_id, "match", 70,
                    f"GPL family matched but -only/-or-later ambiguous from COPYING alone; "
                    f"{best_data[2]}"))
            else:
                component_results.append((decl_id, "match", best_data[1], best_data[2]))
            continue

        component_results.append((decl_id, "not-found", 0,
            f"no text match; found IDs: {sorted({d[0] for d in all_found})}"))

    mismatches = [r for r in component_results if r[1] == "mismatch"]
    not_founds = [r for r in component_results if r[1] == "not-found"]
    unverified = [r for r in component_results if r[1] == "unverified"]
    matches    = [r for r in component_results if r[1] == "match"]

    if mismatches:
        details = "; ".join(f"{r[0]}: {r[3]}" for r in mismatches)
        return (f"incorrect - {details}",
                f"files: {list(license_texts.keys())[:5]}")

    evidence = "; ".join(f"{r[0]}: {r[3]}" for r in component_results)
    evidence = evidence[:300]

    if not_founds:
        missing = ", ".join(r[0] for r in not_founds)
        min_c   = min((r[2] for r in matches), default=50)
        adj     = max(45, min_c - 20)
        return (f"believe correct - {adj}% - no text match for: {missing}", evidence)

    if unverified:
        uvids = ", ".join(r[0] for r in unverified)
        min_c = min(r[2] for r in component_results)
        return (f"believe correct - {min_c}% - LicenseRef unverified in tarball: {uvids}",
                evidence)

    min_c = min(r[2] for r in component_results)
    if min_c >= 99:
        return "correct - 100%", evidence
    elif min_c >= 90:
        return f"correct - {min_c}%", evidence
    else:
        return (f"believe correct - {min_c}% - text analysis only, no SPDX headers",
                evidence)

# ── No-source detection ───────────────────────────────────────────────────────

def detect_no_source(vals, mk_text):
    """Return a reason string if the package has no scannable source, else None."""
    pkg_url = vals.get("PKG_URL", "").strip()
    if not pkg_url:
        if re.search(r"unpack\(\)|PKG_DEPENDS_UNPACK", mk_text):
            m = re.search(r'SOURCES/(\S+?)/', mk_text)
            parent = m.group(1) if m else "another-package"
            return f"source-is-{parent}"
        return "meta-package (no PKG_URL)"
    if pkg_url.startswith("$(") or pkg_url.startswith("${"):
        return None
    url_ext = Path(pkg_url.split("/")[-1]).suffix.lower()
    if url_ext in NON_TARBALL_EXTS:
        return f"non-tarball source ({url_ext})"
    return None

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Validate PKG_LICENSE fields against source tarballs."
    )
    parser.add_argument(
        "package",
        nargs="?",
        help="Process only this package name (optional; processes all if omitted)",
    )
    parser.add_argument(
        "-o", "--output",
        default="license_validation.csv",
        help="CSV output file (default: license_validation.csv in current directory)",
    )
    args = parser.parse_args()

    out = Path(args.output)

    mk_files = sorted(REPO.glob("packages/**/package.mk"))
    total    = len(mk_files)
    if args.package:
        print(f"Scanning for package '{args.package}'...", file=sys.stderr)
    else:
        print(f"Scanning {total} package.mk files...", file=sys.stderr)

    rows = []
    n    = 0

    for mk_path in mk_files:
        vals     = parse_mk(mk_path)
        pkg_name = vals.get("PKG_NAME", "")
        pkg_ver  = vals.get("PKG_VERSION", "")
        pkg_lic  = vals.get("PKG_LICENSE", "")
        rel_path = str(mk_path.relative_to(REPO))

        if not pkg_name or not pkg_lic:
            continue

        if args.package and pkg_name != args.package:
            continue

        mk_text = mk_path.read_text(errors="replace")

        no_src = detect_no_source(vals, mk_text)
        if no_src:
            rows.append(dict(pkg_name=pkg_name, pkg_license=pkg_lic,
                             status=f"no-source - {no_src}",
                             evidence="", pkg_path=rel_path))
            continue

        pkg_src_name = vals.get("PKG_SOURCE_NAME", "")
        tb, ver_matched = find_tarball(pkg_name, pkg_ver, pkg_source_name=pkg_src_name)
        if tb is None:
            rows.append(dict(pkg_name=pkg_name, pkg_license=pkg_lic,
                             status="missing-tarball",
                             evidence=f"not found in {SOURCES / pkg_name}/",
                             pkg_path=rel_path))
            continue

        tb_note = tb.name if ver_matched else f"FALLBACK:{tb.name}"

        lic_texts, spdx_hdrs, err = read_tarball(tb)
        if err:
            rows.append(dict(pkg_name=pkg_name, pkg_license=pkg_lic,
                             status=f"tarball-error - {err}",
                             evidence=tb_note, pkg_path=rel_path))
            continue

        status, evidence = classify(pkg_name, pkg_lic, lic_texts, spdx_hdrs)
        rows.append(dict(pkg_name=pkg_name, pkg_license=pkg_lic,
                         status=status,
                         evidence=f"[{tb_note}] {evidence}"[:300],
                         pkg_path=rel_path))

        n += 1
        if n % 100 == 0:
            print(f"  {n} tarballs processed...", file=sys.stderr)

    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(
            f, fieldnames=["pkg_name", "pkg_license", "status", "evidence", "pkg_path"]
        )
        w.writeheader()
        w.writerows(rows)

    def ct(prefix):
        return sum(1 for r in rows if r["status"].startswith(prefix))

    correct100 = ct("correct - 100%")
    correctlt  = sum(1 for r in rows
                     if re.match(r"correct - \d+%", r["status"])
                     and not r["status"].startswith("correct - 100%"))
    believe    = ct("believe correct")
    incorrect  = ct("incorrect")
    no_src     = ct("no-source")
    no_tb      = ct("missing-tarball")
    errors     = ct("tarball-error")
    other      = (len(rows) - correct100 - correctlt - believe
                  - incorrect - no_src - no_tb - errors)

    print(f"\n{'='*60}", file=sys.stderr)
    print(f"Total rows:              {len(rows)}", file=sys.stderr)
    print(f"correct - 100%:          {correct100}", file=sys.stderr)
    print(f"correct - <100%:         {correctlt}", file=sys.stderr)
    print(f"believe correct:         {believe}", file=sys.stderr)
    print(f"incorrect:               {incorrect}", file=sys.stderr)
    print(f"no-source:               {no_src}", file=sys.stderr)
    print(f"missing-tarball:         {no_tb}", file=sys.stderr)
    print(f"tarball-error:           {errors}", file=sys.stderr)
    print(f"other:                   {other}", file=sys.stderr)
    print(f"\nCSV written to: {out}", file=sys.stderr)

    bad = [r for r in rows if r["status"].startswith("incorrect")]
    if bad:
        print(f"\n{'='*60}", file=sys.stderr)
        print(f"INCORRECT ({len(bad)}):", file=sys.stderr)
        for r in bad:
            print(f"  {r['pkg_name']}: {r['status']}", file=sys.stderr)

    tb_errors = [r for r in rows if r["status"].startswith("tarball-error")]
    if tb_errors:
        print(f"\n{'='*60}", file=sys.stderr)
        print(f"TARBALL ERRORS ({len(tb_errors)}):", file=sys.stderr)
        for r in tb_errors:
            print(f"  {r['pkg_name']}: {r['status']} (file: {r['evidence']})",
                  file=sys.stderr)

    missing = [r for r in rows if r["status"] == "missing-tarball"]
    if missing:
        print(f"\n{'='*60}", file=sys.stderr)
        print(f"MISSING TARBALLS ({len(missing)}) — run scripts/get or download manually:",
              file=sys.stderr)
        for r in missing:
            print(f"  {r['pkg_name']} ({r['pkg_path']})", file=sys.stderr)


if __name__ == "__main__":
    main()
