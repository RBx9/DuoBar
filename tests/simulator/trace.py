#!/usr/bin/env python3
"""Summarise a DuoProbe Control Center trace.

Prints a sample only when DuoBar's or the battery's on-screen frames change,
so a jump while Control Center opens or closes shows up as a short list.
Usage: trace.py springboard-probe.txt
"""
import re
import sys

previous = None
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    match = re.search(r"trace (\w+) t=([\d.]+) (.*)$", line)
    if not match:
        if "DUOPROBE" in line and (" cc " in line or "DuoGlyphView" in line):
            print(line.rstrip())
        continue
    phase, t, items = match.groups()
    # Keep visible glyphs and batteries only; drop hidden ones and opacity noise.
    state = sorted(item.strip() for item in items.split(" | ")
                   if item.strip() and "(hidden)" not in item and "alpha=0.00" not in item)
    key = (phase, tuple(re.sub(r" alpha=[\d.]+", "", item) for item in state))
    if key != previous:
        print(f"{phase:5s} t={t}  " + " | ".join(state))
        previous = key
