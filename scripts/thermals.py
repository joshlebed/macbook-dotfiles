#!/usr/bin/env python3
"""Read Apple Silicon temperatures, fan speeds and power rails from the SMC.

No sudo, no dependencies — talks to the AppleSMC IOKit user client directly.

    ./scripts/thermals.py            one-shot summary
    ./scripts/thermals.py -w         live view, refreshes every 2s
    ./scripts/thermals.py -w -i 0.5  live view, custom interval
    ./scripts/thermals.py --all      include every named sensor, not just groups
    ./scripts/thermals.py --json     machine-readable, for scripting
"""

import argparse
import ctypes
import json
import os
import shutil
import signal
import struct
import sys
import time

# ---------------------------------------------------------------- SMC plumbing

IOKIT = ctypes.CDLL("/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit")
LIBC = ctypes.CDLL("/usr/lib/libSystem.dylib")

KERNEL_INDEX_SMC = 2
SMC_CMD_READ_BYTES = 5
SMC_CMD_READ_KEYINFO = 9
SMC_CMD_READ_INDEX = 8


class _Vers(ctypes.Structure):
    _fields_ = [("major", ctypes.c_ubyte), ("minor", ctypes.c_ubyte),
                ("build", ctypes.c_ubyte), ("reserved", ctypes.c_ubyte),
                ("release", ctypes.c_uint16)]


class _PLimit(ctypes.Structure):
    _fields_ = [("version", ctypes.c_uint16), ("length", ctypes.c_uint16),
                ("cpuPLimit", ctypes.c_uint32), ("gpuPLimit", ctypes.c_uint32),
                ("memPLimit", ctypes.c_uint32)]


class _KeyInfo(ctypes.Structure):
    _fields_ = [("dataSize", ctypes.c_uint32), ("dataType", ctypes.c_uint32),
                ("dataAttributes", ctypes.c_ubyte)]


class _KeyData(ctypes.Structure):
    _fields_ = [("key", ctypes.c_uint32), ("vers", _Vers), ("pLimitData", _PLimit),
                ("keyInfo", _KeyInfo), ("result", ctypes.c_ubyte),
                ("status", ctypes.c_ubyte), ("data8", ctypes.c_ubyte),
                ("data32", ctypes.c_uint32), ("bytes", ctypes.c_ubyte * 32)]


IOKIT.IOServiceMatching.restype = ctypes.c_void_p
IOKIT.IOServiceMatching.argtypes = [ctypes.c_char_p]
IOKIT.IOServiceGetMatchingService.restype = ctypes.c_uint
IOKIT.IOServiceGetMatchingService.argtypes = [ctypes.c_uint, ctypes.c_void_p]
IOKIT.IOServiceOpen.restype = ctypes.c_int
IOKIT.IOServiceOpen.argtypes = [ctypes.c_uint, ctypes.c_uint, ctypes.c_uint,
                                ctypes.POINTER(ctypes.c_uint)]
IOKIT.IOConnectCallStructMethod.restype = ctypes.c_int
IOKIT.IOConnectCallStructMethod.argtypes = [ctypes.c_uint, ctypes.c_uint, ctypes.c_void_p,
                                            ctypes.c_size_t, ctypes.c_void_p,
                                            ctypes.POINTER(ctypes.c_size_t)]

_conn = ctypes.c_uint(0)


def smc_open():
    svc = IOKIT.IOServiceGetMatchingService(0, IOKIT.IOServiceMatching(b"AppleSMC"))
    if not svc:
        sys.exit("AppleSMC service not found — is this an Intel Mac or a VM?")
    task = ctypes.c_uint.in_dll(LIBC, "mach_task_self_").value
    rc = IOKIT.IOServiceOpen(svc, task, 0, ctypes.byref(_conn))
    if rc != 0:
        sys.exit("could not open AppleSMC (0x%x)" % (rc & 0xFFFFFFFF))


def _call(inp):
    out = _KeyData()
    size = ctypes.c_size_t(ctypes.sizeof(_KeyData))
    rc = IOKIT.IOConnectCallStructMethod(_conn, KERNEL_INDEX_SMC, ctypes.byref(inp),
                                         ctypes.sizeof(_KeyData), ctypes.byref(out),
                                         ctypes.byref(size))
    return None if rc != 0 or out.result != 0 else out


def _decode(dtype, raw):
    try:
        if dtype == "flt" and len(raw) == 4:
            return struct.unpack("<f", raw)[0]
        if dtype == "ui8":
            return raw[0]
        if dtype == "ui16":
            return struct.unpack(">H", raw[:2])[0]
        if dtype == "ui32":
            return struct.unpack(">I", raw[:4])[0]
        if dtype == "si16":
            return struct.unpack(">h", raw[:2])[0]
        if dtype == "sp78":
            return struct.unpack(">h", raw[:2])[0] / 256.0
        if dtype == "fpe2":
            return struct.unpack(">H", raw[:2])[0] / 4.0
    except (struct.error, IndexError):
        pass
    return None


def read_key(key):
    """Return the decoded value of an SMC key, or None."""
    inp = _KeyData()
    inp.key = struct.unpack(">I", key.encode())[0]
    inp.data8 = SMC_CMD_READ_KEYINFO
    info = _call(inp)
    if info is None:
        return None

    inp = _KeyData()
    inp.key = struct.unpack(">I", key.encode())[0]
    inp.keyInfo.dataSize = info.keyInfo.dataSize
    inp.data8 = SMC_CMD_READ_BYTES
    res = _call(inp)
    if res is None:
        return None
    dtype = struct.pack(">I", info.keyInfo.dataType).decode("ascii", "replace").strip("\x00 ")
    return _decode(dtype, bytes(res.bytes)[:info.keyInfo.dataSize])


def all_keys():
    """Enumerate every SMC key name once, so refreshes only re-read what matters."""
    count = read_key("#KEY")
    keys = []
    for i in range(int(count or 0)):
        inp = _KeyData()
        inp.data8 = SMC_CMD_READ_INDEX
        inp.data32 = i
        out = _call(inp)
        if out:
            keys.append(struct.pack(">I", out.key).decode("ascii", "replace"))
    return keys


# ------------------------------------------------------------- sensor grouping

# Prefix groups: (label, prefix, exclude-set). Apple exposes dozens of dies per
# group on a Max-class chip, so these are summarised as min/avg/max.
GROUPS = [
    ("CPU cores",      "Tp"),
    ("GPU cores",      "Tg"),
    ("Memory / fabric", "Tm"),
    ("SoC package",    "TVD"),
]

# Individually meaningful keys. Names beyond the well-known ones (battery, NAND,
# fans) are inferred from Apple's fourcc conventions, not documented.
SINGLES = [
    ("Package (TCMb)", "TCMb"),
    ("Airflow",        "Ta00"),
    ("Top plate",      "TaTP"),
    ("Left palm rest", "TaLP"),
    ("Right palm rest", "TaRF"),
    ("Wi-Fi",          "TW0P"),
    ("SSD controller", "TS0P"),
    ("NAND ch0",       "TN00"),
    ("NAND ch1",       "TN01"),
    ("NAND ch2",       "TN02"),
    ("NAND ch3",       "TN03"),
    ("Battery 1",      "TB0T"),
    ("Battery 2",      "TB1T"),
    ("Battery 3",      "TB2T"),
]

POWER = [
    ("Total input",  "PDTR"),
    ("SoC rail",     "PSTR"),
    ("Heatpipe/core", "PHPC"),
    ("System 5V",    "P5SR"),
    ("System 3.3V",  "P3F2"),
]

# Static trip-point keys that look like scorching temperatures but never change.
SKIP_PREFIXES = ("Tf",)


# ------------------------------------------------------------------- rendering

class C:
    RESET = "\033[0m"
    DIM = "\033[2m"
    BOLD = "\033[1m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    ORANGE = "\033[38;5;208m"
    RED = "\033[31m"
    CYAN = "\033[36m"
    GREY = "\033[38;5;244m"


def _supports_color():
    return sys.stdout.isatty() and os.environ.get("TERM", "") != "dumb"


NOCOLOR = False


def paint(s, color):
    return s if NOCOLOR else color + s + C.RESET


def temp_color(v):
    if v < 50:
        return C.GREEN
    if v < 70:
        return C.YELLOW
    if v < 85:
        return C.ORANGE
    return C.RED


def bar(frac, width=22):
    frac = max(0.0, min(1.0, frac))
    filled = int(round(frac * width))
    if frac < 0.5:
        col = C.GREEN
    elif frac < 0.75:
        col = C.YELLOW
    elif frac < 0.9:
        col = C.ORANGE
    else:
        col = C.RED
    return paint("█" * filled, col) + paint("░" * (width - filled), C.GREY)


def collect(keys):
    """Read one full snapshot."""
    temps, fans, power = {}, {}, {}
    for k in keys:
        if k.startswith(SKIP_PREFIXES):
            continue
        if k[0] == "T":
            v = read_key(k)
            if isinstance(v, float) and -50 < v < 130:
                temps[k] = v
        elif k[0] == "F" and (k.endswith(("Ac", "Tg", "Mn", "Mx")) or k == "FNum"):
            v = read_key(k)
            if v is not None:
                fans[k] = v
        elif k in [p[1] for p in POWER]:
            v = read_key(k)
            if isinstance(v, float):
                power[k] = v
    return temps, fans, power


def render(temps, fans, power, show_all):
    w = shutil.get_terminal_size((90, 40)).columns
    out = []

    def head(t):
        out.append("")
        out.append(paint(t.upper(), C.BOLD + C.CYAN) + " " + paint("─" * max(0, w - len(t) - 2), C.GREY))

    head("temperatures")
    for label, pfx in GROUPS:
        vals = [v for k, v in temps.items() if k.startswith(pfx)]
        if not vals:
            continue
        lo, hi = min(vals), max(vals)
        avg = sum(vals) / len(vals)
        out.append("  %-17s %s  %s  %s   %s" % (
            label,
            paint("%5.1f°" % lo, C.GREY),
            paint("%5.1f°" % avg, temp_color(avg)),
            paint("%5.1f°" % hi, temp_color(hi)),
            paint("%d sensors  (min / avg / max)" % len(vals), C.GREY)))

    out.append("")
    for label, key in SINGLES:
        if key not in temps:
            continue
        v = temps[key]
        out.append("  %-17s %s  %s" % (label, paint("%5.1f°C" % v, temp_color(v)),
                                       bar(v / 100.0)))

    if show_all:
        head("all named sensors")
        known = {k for _, k in SINGLES}
        rest = sorted((k, v) for k, v in temps.items()
                      if k not in known and not any(k.startswith(p) for _, p in GROUPS))
        for i in range(0, len(rest), 4):
            row = rest[i:i + 4]
            out.append("  " + "".join("%s %s   " % (paint(k, C.GREY),
                                                    paint("%5.1f°" % v, temp_color(v)))
                                      for k, v in row))

    head("fans")
    n = int(fans.get("FNum", 0) or 0)
    for i in range(n):
        cur = fans.get("F%dAc" % i)
        mx = fans.get("F%dMx" % i) or 1
        mn = fans.get("F%dMn" % i) or 0
        tgt = fans.get("F%dTg" % i)
        if cur is None:
            continue
        pct = cur / mx
        out.append("  %-17s %s  %s  %s" % (
            "Fan %d" % i,
            paint("%5.0f rpm" % cur, temp_color(30 + pct * 70)),
            bar(pct),
            paint("%3.0f%% of max   target %.0f   range %.0f–%.0f" % (pct * 100, tgt or 0, mn, mx), C.GREY)))

    if power:
        head("power")
        for label, key in POWER:
            if key in power:
                out.append("  %-17s %s" % (label, paint("%6.2f W" % power[key], C.CYAN)))

    return "\n".join(out)


# ------------------------------------------------------------------------ main

def main():
    global NOCOLOR
    ap = argparse.ArgumentParser(description="Apple Silicon temps, fans and power from the SMC.")
    ap.add_argument("-w", "--watch", action="store_true", help="refresh continuously")
    ap.add_argument("-i", "--interval", type=float, default=2.0, help="refresh seconds (default 2)")
    ap.add_argument("-a", "--all", action="store_true", help="list every named sensor")
    ap.add_argument("--json", action="store_true", help="emit JSON and exit")
    ap.add_argument("--no-color", action="store_true")
    args = ap.parse_args()

    NOCOLOR = args.no_color or not _supports_color()

    smc_open()
    keys = all_keys()

    if args.json:
        temps, fans, power = collect(keys)
        print(json.dumps({"temps": temps, "fans": fans, "power": power}, indent=2, sort_keys=True))
        return

    if not args.watch:
        temps, fans, power = collect(keys)
        print(render(temps, fans, power, args.all))
        print()
        return

    # Alternate screen buffer so the scrollback survives the session.
    sys.stdout.write("\033[?1049h\033[?25l")
    signal.signal(signal.SIGINT, lambda *_: (_ for _ in ()).throw(KeyboardInterrupt))
    try:
        while True:
            temps, fans, power = collect(keys)
            body = render(temps, fans, power, args.all)
            sys.stdout.write("\033[H\033[J")
            sys.stdout.write(paint(time.strftime("  %H:%M:%S"), C.GREY) +
                             paint("   ctrl-c to quit\n", C.DIM))
            sys.stdout.write(body + "\n")
            sys.stdout.flush()
            time.sleep(args.interval)
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write("\033[?25h\033[?1049l")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
