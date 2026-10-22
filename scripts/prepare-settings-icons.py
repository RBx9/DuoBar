#!/usr/bin/env python3
"""Remove the white, opaque square behind DuoBar's rounded Settings icon.

The original artwork has white corner pixels. Flood-fill only white/near-white
pixels connected to the outer image boundary, preserving the white Wi-Fi and
percentage artwork inside the blue icon.
"""
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOCATIONS = [
    ROOT / "duobarprefs/Resources",
    ROOT / "layout/Library/PreferenceLoader/Preferences",
]
NAMES = ("DuoBar.png", "DuoBar@2x.png", "DuoBar@3x.png")


def remove_background(path: Path) -> None:
    im = Image.open(path).convert("RGBA")
    width, height = im.size
    pixels = im.load()

    def background(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        return a > 0 and min(r, g, b) >= 235 and max(r, g, b) - min(r, g, b) <= 16

    seen = bytearray(width * height)
    queue = deque()
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    removed = 0
    while queue:
        x, y = queue.popleft()
        i = y * width + x
        if seen[i]:
            continue
        seen[i] = 1
        if not background(x, y):
            continue
        pixels[x, y] = (0, 0, 0, 0)
        removed += 1
        if x > 0:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))

    if removed == 0:
        raise RuntimeError(f"No opaque white border found in {path}; inspect asset manually")
    if removed > width * height * 0.40:
        raise RuntimeError(f"Removed suspiciously large area ({removed} pixels) from {path}")
    im.save(path, optimize=True)
    assert im.getpixel((0, 0))[3] == 0
    print(f"Cleaned {path.relative_to(ROOT)}: {removed} white corner pixels removed")


for location in LOCATIONS:
    for name in NAMES:
        remove_background(location / name)
