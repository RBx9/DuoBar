#!/usr/bin/env python3
"""One line per simulator scene: DuoBar's frame, whether it is fully on
screen, overlaps with status-bar items DuoBar does not cover, and the
Control Center handoff jump.
Usage: summary.py <shots-dir>
"""
import re
import sys
from pathlib import Path

RECT = r"\{(-?[\d.]+),(-?[\d.]+),([\d.]+),([\d.]+)\}"
COVERED_TEXT = re.compile(r"^(5G.*|LTE.*|\d{1,3}%)$")


def rect(text):
    return tuple(float(v) for v in re.match(RECT, text).groups())


def overlap(a, b):
    w = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
    h = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
    return w * h if w > 0.5 and h > 0.5 else 0.0


def scene(lines, label):
    screen = None
    glyphs, items = [], []
    for line in lines:
        m = re.search(r"screen bounds=" + RECT, line)
        if m:
            screen = tuple(float(v) for v in m.groups())
        m = re.search(r"view depth=\d+ (\S+) frame=\S+ window=(" + RECT + r") hidden=0 alpha=[\d.]+ clips=\d "
                      r"visible=1 text=\"(.*?)\"", line)
        if not m:
            continue
        cls, r, text = m.group(1), rect(m.group(2)), m.group(7)
        if cls == "DuoGlyphView":
            glyphs.append(r)
        elif cls in ("_UIStatusBarStringView", "_UIStatusBarImageView") and r[2] > 1 and r[3] > 1 \
                and not COVERED_TEXT.match(text.strip()):
            items.append((cls.replace("_UIStatusBar", ""), text, r))
    if not glyphs:
        return f"{label}: no visible DuoBar"
    parts = []
    for g in glyphs:
        onscreen = screen is None or (g[0] >= -0.01 and g[1] >= -0.01 and
                                      g[0] + g[2] <= screen[2] + 0.01 and g[1] + g[3] <= screen[3] + 0.01)
        hits = [f"{name}'{text}'" for name, text, r in items if overlap(g, r)]
        parts.append(f"ring={g[2]:.1f}x{g[3]:.1f}@({g[0]:.1f},{g[1]:.1f}) "
                     f"{'on-screen' if onscreen else 'OFF-SCREEN'} overlaps={','.join(hits) or 'none'}")
    return f"{label}: " + " ; ".join(parts)


def main():
    shots = Path(sys.argv[1])
    for path in sorted(shots.glob("*-app-*.txt")):
        name = path.stem
        print(scene(path.read_text(errors="replace").splitlines(), f"app  {name}"))
    for path in sorted(shots.glob("*-springboard-*.txt")):
        lines = path.read_text(errors="replace").splitlines()
        # Layout dumps: at start (Home Screen), with Control Center open, after closing.
        cut_open = next((i for i, l in enumerate(lines) if "cc dismiss called" in l), len(lines))
        cut_present = next((i for i, l in enumerate(lines) if "cc present called" in l), cut_open)
        print(scene(lines[:cut_present], f"home {path.stem}"))
        open_dump = [l for l in lines[cut_present:cut_open] if "trace " not in l]
        print(scene(open_dump, f"cc   {path.stem}"))
        summary = Path(str(path) + ".summary")
        if summary.exists():
            handoff = [l for l in summary.read_text().splitlines() if l.startswith("handoff")]
            print(f"jump {path.stem}: {handoff[-1] if handoff else 'no trace'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
