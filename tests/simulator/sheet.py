#!/usr/bin/env python3
"""Crop the status-bar area around DuoBar from simulator screenshots and
assemble one labelled contact sheet.

Usage: sheet.py manifest.tsv output.png
manifest.tsv lines: label<TAB>screenshot.png<TAB>probe-output.txt
The crop uses the screen scale, status-bar height and DuoBar frame the probe
reported, and is drawn at 2 px per point.
"""
import re
import sys

from PIL import Image, ImageDraw

RECT = r"\{(-?[\d.]+),(-?[\d.]+),([\d.]+),([\d.]+)\}"


def geometry(probe_path):
    text = open(probe_path, encoding="utf-8", errors="replace").read()
    screen = re.search(r"screen bounds=" + RECT + r" scale=(\d+)", text)
    width, scale = (float(screen.group(3)), float(screen.group(5))) if screen else (390.0, 3.0)
    bars = [float(value) for value in re.findall(r"statusBar=([\d.]+)", text)]
    status_bar = max(bars) if bars else 54.0
    glyph = None
    for match in re.finditer(r"DuoGlyphView frame=\S+ window=" + RECT + r" hidden=0", text):
        glyph = tuple(float(match.group(i)) for i in range(1, 5))
    return width, scale, status_bar, glyph


def main():
    manifest, output = sys.argv[1], sys.argv[2]
    cells = []
    for line in open(manifest, encoding="utf-8"):
        label, png, probe = line.rstrip("\n").split("\t")
        try:
            shot = Image.open(png).convert("RGB")
        except OSError:
            continue
        width, scale, status_bar, glyph = geometry(probe)
        if glyph:
            left = max(0.0, glyph[0] - 80)
            bottom = max(status_bar, glyph[1] + glyph[3]) + 8
        else:
            left, bottom = width - 180, status_bar + 8
        box = tuple(int(round(v * scale)) for v in (left, 0, width, bottom))
        crop = shot.crop(box)
        crop = crop.resize((max(1, int(crop.width * 2 / scale)), max(1, int(crop.height * 2 / scale))),
                           Image.LANCZOS)
        cells.append((f"{label}{'' if glyph else ' [no DuoBar]'}", crop))
    if not cells:
        return 1
    columns = 5
    cell_w = max(crop.width for _, crop in cells)
    cell_h = max(crop.height for _, crop in cells) + 14
    rows = (len(cells) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * (cell_w + 6), rows * (cell_h + 6)), (200, 200, 200))
    draw = ImageDraw.Draw(sheet)
    for index, (label, crop) in enumerate(cells):
        x = (index % columns) * (cell_w + 6)
        y = (index // columns) * (cell_h + 6)
        sheet.paste(crop, (x, y))
        draw.text((x + 2, y + crop.height + 1), label[:48], fill=(0, 0, 0))
    sheet.quantize(colors=96).save(output, optimize=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
