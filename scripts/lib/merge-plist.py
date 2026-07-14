#!/usr/bin/env python3
"""Merge a repo-tracked plist overlay onto the live system domain.

The repo stores a *filtered* plist: churn keys (window frames, launch counts,
analytics identity) are deliberately stripped by normalize-plist.py. That makes
the committed file a partial description of the domain, not a replacement for
it — so it must never be written over the system plist wholesale.

`defaults import` replaces the entire domain. Importing the filtered file
directly would delete every stripped key from the live domain. On a fresh Mac
that is harmless (they do not exist yet), but on a machine that is already set
up it would wipe window positions and update state on every link-files run.

So: read the live domain as the base, overlay the tracked keys on top, and
import the union. Tracked settings win; untracked local churn is preserved.

Usage:
    merge-plist.py --base BASE.plist --overlay OVERLAY.plist --out OUT.plist
    merge-plist.py --overlay OVERLAY.plist --out OUT.plist       # no base

Dependency-free: system python3 (3.9), no PyYAML.
"""

import argparse
import os
import plistlib
import sys


def load(path):
    if not path or not os.path.exists(path):
        return {}
    try:
        with open(path, "rb") as fh:
            data = plistlib.load(fh)
    except Exception as exc:
        print("merge-plist: cannot read %s: %s" % (path, exc), file=sys.stderr)
        raise SystemExit(1)
    return data if isinstance(data, dict) else {}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base", default=None, help="live system domain export (optional)")
    ap.add_argument("--overlay", required=True, help="repo-tracked normalized plist")
    ap.add_argument("--out", required=True)
    ap.add_argument("--report", action="store_true")
    args = ap.parse_args()

    base = load(args.base)
    overlay = load(args.overlay)

    if not overlay:
        print("merge-plist: overlay %s is empty" % args.overlay, file=sys.stderr)
        return 1

    merged = dict(base)
    changed = []
    for k, v in overlay.items():
        if base.get(k) != v:
            changed.append(k)
        merged[k] = v

    with open(args.out, "wb") as fh:
        plistlib.dump(merged, fh, fmt=plistlib.FMT_XML, sort_keys=True)

    if args.report:
        print(
            "      base=%d keys, overlay=%d keys, merged=%d keys, changing=%d"
            % (len(base), len(overlay), len(merged), len(changed)),
            file=sys.stderr,
        )
        for k in sorted(changed):
            print("        ~ %s" % k, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
