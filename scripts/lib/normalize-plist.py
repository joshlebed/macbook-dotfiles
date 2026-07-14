#!/usr/bin/env python3
"""Normalize a macOS plist into a stable, reviewable, diffable form.

Raw plists are a bad thing to keep in git:

  * They are binary, so every change is "Binary files differ" in a diff/PR.
  * They interleave real settings with churn (launch counts, window frames,
    update timestamps, analytics IDs), so byte-comparison reports drift on
    every export.
  * Some values are *semantically identical but byte-different*: Thaw stores
    JSON blobs whose key order is not stable across writes, so those keys can
    never compare equal no matter what you do.

This script fixes all three: it strips filtered keys, canonicalises embedded
JSON, and emits sorted XML. Two normalized files compare equal iff the
settings they represent are equal.

Usage:
    normalize-plist.py --filters F.yaml --domain D --in IN.plist --out OUT.plist
    normalize-plist.py --filters F.yaml --domain D --in IN.plist --out -

Deliberately dependency-free: a fresh Mac has only system python3 (3.9) with
no PyYAML, and this has to run before Homebrew does anything.
"""

import argparse
import fnmatch
import json
import plistlib
import re
import sys


def parse_filters(path):
    """Parse the tiny YAML subset used by preference-filters.yaml.

    Only supports:  top-level `key:` or `"key":` followed by `- "pattern"`
    list items. Written by hand because system python3 has no PyYAML.
    """
    sections = {}
    current = None
    with open(path, "r") as fh:
        for raw in fh:
            line = raw.split("#", 1)[0].rstrip() if not raw.strip().startswith("#") else ""
            if not line.strip():
                continue
            item = re.match(r'^\s*-\s*"?([^"]+)"?\s*$', line)
            if item and current is not None:
                sections[current].append(item.group(1))
                continue
            head = re.match(r'^"?([^":]+)"?:\s*$', line)
            if head:
                current = head.group(1)
                sections.setdefault(current, [])
    return sections


def patterns_for(sections, domain):
    return list(sections.get("*", [])) + list(sections.get(domain, []))


def should_drop(key, patterns):
    return any(fnmatch.fnmatch(key, p) for p in patterns)


def canonicalize(value):
    """Recursively canonicalise a plist value.

    The important part is embedded JSON. Thaw stores `IceIcon` and
    `MenuBarAppearanceConfigurationV2` as JSON-in-bytes, and Velja stores
    `rules` as a list of JSON strings. In both cases the app's encoder does
    not guarantee key order, so re-serialising with sorted keys is what makes
    an unchanged setting compare equal to itself across exports.
    """
    if isinstance(value, dict):
        return {k: canonicalize(value[k]) for k in sorted(value)}
    if isinstance(value, list):
        return [canonicalize(v) for v in value]
    if isinstance(value, bytes):
        try:
            return json.dumps(
                json.loads(value.decode("utf-8")), sort_keys=True, separators=(",", ":")
            ).encode("utf-8")
        except Exception:
            return value  # genuinely binary (keyed archives, bookmarks) — leave alone
    if isinstance(value, str):
        stripped = value.strip()
        if stripped[:1] in ("{", "[") and stripped[-1:] in ("}", "]"):
            try:
                return json.dumps(
                    json.loads(value), sort_keys=True, separators=(",", ":")
                )
            except Exception:
                return value
    return value


def normalize(data, patterns):
    kept = {k: canonicalize(v) for k, v in data.items() if not should_drop(k, patterns)}
    dropped = sorted(k for k in data if should_drop(k, patterns))
    return {k: kept[k] for k in sorted(kept)}, dropped


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--filters", required=True)
    ap.add_argument("--domain", required=True)
    ap.add_argument("--in", dest="infile", required=True)
    ap.add_argument("--out", dest="outfile", required=True, help='"-" for stdout')
    ap.add_argument("--report-dropped", action="store_true")
    args = ap.parse_args()

    try:
        with open(args.infile, "rb") as fh:
            data = plistlib.load(fh)
    except Exception as exc:
        print("normalize-plist: cannot read %s: %s" % (args.infile, exc), file=sys.stderr)
        return 1

    if not isinstance(data, dict):
        print("normalize-plist: %s is not a plist dictionary" % args.infile, file=sys.stderr)
        return 1

    patterns = patterns_for(parse_filters(args.filters), args.domain)
    result, dropped = normalize(data, patterns)

    blob = plistlib.dumps(result, fmt=plistlib.FMT_XML, sort_keys=True)
    if args.outfile == "-":
        sys.stdout.buffer.write(blob)
    else:
        with open(args.outfile, "wb") as fh:
            fh.write(blob)

    if args.report_dropped:
        print(
            "  %s: kept %d, stripped %d" % (args.domain, len(result), len(dropped)),
            file=sys.stderr,
        )
        for k in dropped:
            print("      - %s" % k, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
