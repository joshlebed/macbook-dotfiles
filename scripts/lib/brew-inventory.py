#!/usr/bin/env python3
"""Report what Homebrew actually has installed, in Brewfile terms.

Why this exists: brew's own reporting cannot be trusted for this job.

  * `brew leaves` omits every third-party-tap formula.
  * `brew bundle dump` omits them too, even when the receipt says
    installed_on_request.
  * `brew info --json=v2 --installed` returns ONLY homebrew/core formulae — the
    tap ones are absent entirely.

All three hid the same 8 packages here (graphite, terraform, k9s, supabase,
infisical, nightlight, pup, shell-ai), which is how they stayed undeclared for
so long. The Cellar/Caskroom install receipts on disk are the one source that
sees everything, so read those.

Usage:
    brew-inventory.py --formulae   # on-request formulae, tap-qualified
    brew-inventory.py --casks      # installed cask tokens
    brew-inventory.py --apps       # ".app" bundles present in /Applications
    brew-inventory.py --cask-presence TOKEN...  # "token<TAB>evidence" ("" if absent)
"""

import argparse
import fnmatch
import glob
import json
import os
import shutil
import subprocess
import sys

CELLAR = "/opt/homebrew/Cellar"
CASKROOM = "/opt/homebrew/Caskroom"

# Casks Homebrew renamed. The Brewfile uses the canonical name, but the old
# token can still be staged in the Caskroom from before the rename, which would
# otherwise show up as undeclared drift.
CASK_ALIASES = {
    "docker": "docker-desktop",
    "logi-options-plus": "logi-options+",
    "google-cloud-sdk": "gcloud-cli",
}


def on_request_formulae():
    out = set()
    for receipt in glob.glob(os.path.join(CELLAR, "*", "*", "INSTALL_RECEIPT.json")):
        name = receipt.split("/Cellar/")[1].split("/")[0]
        try:
            with open(receipt) as fh:
                data = json.load(fh)
        except Exception:
            continue
        if not data.get("installed_on_request"):
            continue
        tap = (data.get("source") or {}).get("tap") or "homebrew/core"
        out.add(name if tap == "homebrew/core" else "%s/%s" % (tap, name))
    return out


def installed_casks():
    out = set()
    if not os.path.isdir(CASKROOM):
        return out
    for path in glob.glob(os.path.join(CASKROOM, "*")):
        if not os.path.isdir(path):
            continue
        token = os.path.basename(path)
        out.add(CASK_ALIASES.get(token, token))
    return out


def applications():
    out = set()
    for d in ("/Applications", os.path.expanduser("~/Applications")):
        if os.path.isdir(d):
            for entry in os.listdir(d):
                if entry.endswith(".app"):
                    out.add(entry[: -len(".app")])
    return out


def pkg_receipts():
    try:
        proc = subprocess.run(["pkgutil", "--pkgs"], capture_output=True, text=True)
        return set(proc.stdout.split())
    except Exception:
        return set()


def _flatten(value):
    """brew's JSON uses a bare string or a list interchangeably."""
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        return [v for v in value if isinstance(v, str)]
    return []


def _binary_names(value):
    """Extract the installed command name from a `binary` artifact.

    The artifact is a mixed list: the payload path plus an optional rename, e.g.
        ["codex-aarch64-apple-darwin", {"target": "codex"}]
    The installed command is the target when present, not the payload name.
    """
    names = []
    rename = None
    for item in value if isinstance(value, list) else [value]:
        if isinstance(item, str):
            names.append(os.path.basename(item))
        elif isinstance(item, dict) and isinstance(item.get("target"), str):
            rename = os.path.basename(item["target"])
    return [rename] if rename else names


def cask_presence(tokens):
    """Decide whether each cask's software is present, however it was installed.

    Read brew's JSON artifacts, never `brew info` prose: the descriptions and
    URLs contain incidental ".app" strings (malwarebytes' text yields
    "developer.app" — and it installs no app at all).

    Casks install three different ways, and checking only for a .app misses two
    of them. Microsoft Office, Zoom, OneDrive and Okta Verify are pkg installers
    with no app artifact; codex ships a bare binary. So check, in order:

      app     -> /Applications
      pkgutil -> the receipt database (authoritative for pkg installs)
      binary  -> on PATH

    brew accepts many tokens per call, so this costs one invocation, not N.
    """
    if not tokens:
        return []
    try:
        proc = subprocess.run(
            ["brew", "info", "--cask", "--json=v2"] + list(tokens),
            capture_output=True,
        )
        data = json.loads(proc.stdout)
    except Exception:
        return []

    apps = applications()
    pkgs = pkg_receipts()
    results = []

    for cask in data.get("casks", []):
        token = cask.get("token")
        evidence = ""
        for art in cask.get("artifacts", []):
            if not isinstance(art, dict) or evidence:
                continue

            for app in _flatten(art.get("app")):
                if app.endswith(".app") and app[: -len(".app")] in apps:
                    evidence = "app '%s'" % app[: -len(".app")]
                    break
            if evidence:
                break

            for entry in art.get("uninstall", []) or []:
                if not isinstance(entry, dict):
                    continue
                # These are glob patterns, not literal IDs: malwarebytes
                # declares "com.malwarebytes.mbam.*", which matches no receipt
                # exactly but does match com.malwarebytes.mbam.installer.
                for pattern in _flatten(entry.get("pkgutil")):
                    hit = next((p for p in pkgs if fnmatch.fnmatch(p, pattern)), None)
                    if hit:
                        evidence = "pkg receipt '%s'" % hit
                        break
                if evidence:
                    break
            if evidence:
                break

            for name in _binary_names(art.get("binary")):
                # shutil.which honours PATH but not shell aliases — an alias is
                # not an installation.
                if shutil.which(name):
                    evidence = "binary '%s'" % name
                    break
            if evidence:
                break

        results.append((token, evidence))
    return results


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--formulae", action="store_true")
    g.add_argument("--casks", action="store_true")
    g.add_argument("--apps", action="store_true")
    g.add_argument("--cask-presence", nargs="*", metavar="TOKEN")
    args = ap.parse_args()

    if args.cask_presence is not None:
        for token, evidence in cask_presence(args.cask_presence):
            print("%s\t%s" % (token, evidence))
        return 0

    if args.formulae:
        items = on_request_formulae()
    elif args.casks:
        items = installed_casks()
    else:
        items = applications()

    for item in sorted(items):
        print(item)
    return 0


if __name__ == "__main__":
    sys.exit(main())
