#!/usr/bin/env python3
"""
Rename patch files to ####-subject.patch (no package name prefix).

Usage:
  python3 rename_plan.py            # dry-run: print plan + warnings
  python3 rename_plan.py --execute  # execute git mv commands then print summary
"""
import os, re, subprocess, sys
from collections import defaultdict

EXCLUDED = [
    'packages/mediacenter/kodi',
    'packages/linux',
]
DRY_RUN = '--execute' not in sys.argv

# ── helpers ────────────────────────────────────────────────────────────────────

def is_excluded(root):
    r = root.replace(os.sep, '/')
    for ex in EXCLUDED:
        if r == ex or r.startswith(ex + '/'):
            return True
    return False

def pkg_from_dir(d):
    """Package name = directory immediately before 'patches/'."""
    parts = d.replace(os.sep, '/').split('/')
    for i, p in enumerate(parts):
        if p == 'patches' and i > 0:
            return parts[i - 1]
    return None

def is_conforming(fname):
    """True iff fname is DDDD-subject.patch or DDDD.patch (no package prefix)."""
    return bool(re.match(r'^\d{4}[.-]', fname))

def extract_4digit_num(fname):
    """Return the 4-digit integer from a conforming filename, or None."""
    m = re.match(r'^(\d{4})', fname)
    return int(m.group(1)) if m else None

def parse_raw_num_and_subj(fname, pkg):
    """
    For a non-conforming fname, return (raw_num_str_or_None, subject_str).
    Strips package prefix if present; otherwise uses whole base as subject.
    X.YY numbers with major<10 are treated as version strings (num=None).
    """
    base = fname[:-6]  # strip .patch
    # Strip package prefix (hyphen or underscore separator)
    if base.startswith(pkg + '-') or base.startswith(pkg + '_'):
        rest = base[len(pkg) + 1:]
    else:
        rest = base

    m = re.match(r'^(\d+(?:\.\d+)*)([_-](.*))?$', rest)
    if m:
        num_str = m.group(1)
        subj    = m.group(3) or ''
        # Detect version strings (e.g. 9.42, 0.5.6, 2.0.5, 1.14)
        if '.' in num_str:
            parts = num_str.split('.')
            if len(parts) > 2 or int(parts[0]) < 10:
                return None, rest
            major, minor = int(parts[0]), int(parts[1])
            return f'{major:02d}{minor:02d}', subj
        return num_str, subj

    # No leading number — check for word-NNNN[-subject] pattern
    m_alt = re.match(r'^[a-zA-Z][a-zA-Z0-9_]*[-_](\d+)(?:[_-](.*))?$', rest)
    if m_alt:
        return m_alt.group(1), m_alt.group(2) or ''
    return None, rest

def to_4digit(num_str):
    return f'{int(num_str):04d}'

# ── collect patches ────────────────────────────────────────────────────────────

by_dir = defaultdict(list)
for root, dirs, files in os.walk('packages'):
    root = root.replace(os.sep, '/')
    if is_excluded(root):
        dirs.clear()
        continue
    for f in sorted(files):
        if f.endswith('.patch'):
            by_dir[root].append(f)

# ── build rename plan ─────────────────────────────────────────────────────────

all_renames    = []
order_warnings = []

for patches_dir in sorted(by_dir):
    pkg = pkg_from_dir(patches_dir)
    if not pkg:
        print(f'WARNING: cannot determine pkg for {patches_dir}', file=sys.stderr)
        continue

    filenames = sorted(by_dir[patches_dir])

    current_max = -1
    proposed = []

    for fname in filenames:
        if is_conforming(fname):
            n = extract_4digit_num(fname)
            current_max = max(current_max, n if n is not None else current_max)
            proposed.append((fname, fname))
            continue

        raw_num_str, subj = parse_raw_num_and_subj(fname, pkg)

        if raw_num_str is not None:
            explicit_n = int(raw_num_str) if len(raw_num_str) <= 4 else int(to_4digit(raw_num_str))
            if explicit_n == 0 and current_max == -1:
                assigned = 0
            elif explicit_n > current_max:
                assigned = explicit_n
            else:
                assigned = current_max + 1
        else:
            assigned = max(1, current_max + 1)

        current_max = assigned
        new_num = f'{assigned:04d}'
        new_fname = f'{new_num}-{subj}.patch' if subj else f'{new_num}.patch'
        proposed.append((fname, new_fname))

    # ── duplicate new-name check ──────────────────────────────────────────────
    seen = {}
    for i, (old, new) in enumerate(proposed):
        if new in seen:
            m2 = re.match(r'^(\d{4})(-.+\.patch|\.patch)$', new)
            if m2:
                n = int(m2.group(1)) + 1
                while f'{n:04d}{m2.group(2)}' in seen:
                    n += 1
                resolved = f'{n:04d}{m2.group(2)}'
                proposed[i] = (old, resolved)
                seen[resolved] = i
        else:
            seen[new] = i

    # ── ordering check ────────────────────────────────────────────────────────
    new_names = [p[1] for p in proposed]
    if sorted(new_names) != new_names:
        order_warnings.append((patches_dir, list(zip([p[0] for p in proposed], new_names))))

    for old_fname, new_fname in proposed:
        if old_fname != new_fname:
            all_renames.append((patches_dir + '/' + old_fname,
                                 patches_dir + '/' + new_fname))

# ── report ordering warnings ──────────────────────────────────────────────────
if order_warnings:
    print('ORDERING WARNINGS (application order would change):', file=sys.stderr)
    for d, pairs in order_warnings:
        print(f'  {d}:', file=sys.stderr)
        for o, n in pairs:
            print(f'    {o}  ->  {n}', file=sys.stderr)
    print(file=sys.stderr)

# ── print plan ────────────────────────────────────────────────────────────────
print(f'Renames needed: {len(all_renames)}\n')
for old, new in all_renames:
    print(f'  {old}')
    print(f'  -> {new}')

# ── execute ───────────────────────────────────────────────────────────────────
if not DRY_RUN:
    print('\nExecuting git mv ...')
    errors = 0
    for old, new in all_renames:
        r = subprocess.run(['git', 'mv', old, new], capture_output=True, text=True)
        if r.returncode != 0:
            print(f'ERROR: {old} -> {new}\n  {r.stderr.strip()}', file=sys.stderr)
            errors += 1
    if errors:
        print(f'{errors} errors.', file=sys.stderr)
    else:
        print(f'Done. {len(all_renames)} files renamed.')
