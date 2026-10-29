#!/usr/bin/env python3
"""Summarise a DuoProbe Control Center trace.

Prints a sample only when a visible DuoBar's or battery's on-screen frame
changes, then the handoff: where Control Center's DuoBar ends as it closes
compared with the Home Screen's DuoBar that replaces it. A non-zero handoff
is a visible jump.
Usage: trace.py springboard-probe.txt
"""
import re
import sys

RECT = r"\{(-?[\d.]+),(-?[\d.]+),([\d.]+),([\d.]+)\}"


def glyphs(items, window):
    return [tuple(float(v) for v in m.groups()) for m in
            re.finditer(r"glyph win=" + window + r" rect=" + RECT, items)]


previous = None
last_cc = None
home = None
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    match = re.search(r"trace (\w+) t=([\d.]+) (.*)$", line)
    if not match:
        if "DUOPROBE" in line and " cc " in line:
            print(line.rstrip())
        continue
    phase, t, items = match.groups()
    state = sorted(item.strip() for item in items.split(" | ") if item.strip())
    key = (phase, tuple(re.sub(r" alpha=[\d.]+", "", item) for item in state))
    if key != previous:
        print(f"{phase:5s} t={t}  " + " | ".join(state))
        previous = key
    if phase == "close":
        cc = glyphs(items, "SBControlCenterWindow")
        if cc:
            last_cc = cc[-1]
        bars = glyphs(items, r"(?!SBControlCenterWindow)\w+")
        if bars and not cc:
            home = bars[-1]

if last_cc and home:
    print(f"handoff cc={last_cc} home={home} dx={home[0] - last_cc[0]:.1f} dy={home[1] - last_cc[1]:.1f} "
          f"dsize={home[3] - last_cc[3]:.1f}")
else:
    print(f"handoff unavailable cc={last_cc} home={home}")
