#!/usr/bin/env python3
"""Generate the 1024x1024 App Store icon for Houston BBQ Guide.

Built from the official Houston BBQ Guide steer logo (pipeline/assets/): isolates
the geometric horned head, recolors it into the app's ember/amber palette, and
composites it onto the smoked-dark background so it reads as a barbecue app while
staying true to the brand mark. Opaque, no alpha — App Store requirement.
"""
from PIL import Image
import math, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(HERE, "assets", "houston-bbq-guide-logo.png")
OUT = os.path.join(ROOT, "HoustonBBQGuide", "Assets.xcassets",
                   "AppIcon.appiconset", "icon-1024.png")
S = 1024

logo = Image.open(SRC).convert("RGBA")
W, H = logo.size
px = logo.load()

# 1. keep only the brand-cyan shards (drop white background, black text, red).
keep = Image.new("RGBA", (W, H), (0, 0, 0, 0)); kp = keep.load()
mask = Image.new("L", (W, H), 0); mp = mask.load()
for y in range(H):
    for x in range(W):
        r, g, b, a = px[x, y]
        if a > 20 and b > 95 and (b - r) > 25 and g > 70:
            kp[x, y] = (r, g, b, 255); mp[x, y] = 255

# 2. crop to the horned head (left of the wordmark, above the muzzle).
cx1, cy1 = int(W * 0.385), int(H * 0.52)
bbox = mask.crop((0, 0, cx1, cy1)).getbbox()
head = keep.crop((0, 0, cx1, cy1)).crop(bbox)
# erase the small detached neck shards in the lower-right corner.
hp = head.load(); hw, hh = head.size
for yy in range(int(hh * 0.80), hh):
    for xx in range(int(hw * 0.58), hw):
        r, g, b, a = hp[xx, yy]; hp[xx, yy] = (r, g, b, 0)
head = head.crop(head.getbbox())

# 3. recolor the head with a vertical amber->ember gradient (keep its alpha).
hp = head.load(); hw, hh = head.size
TOP, BOT = (0xF0, 0xA2, 0x4A), (0xE2, 0x62, 0x2F)
for yy in range(hh):
    t = yy / max(1, hh - 1)
    col = tuple(int(TOP[i] * (1 - t) + BOT[i] * t) for i in range(3))
    for xx in range(hw):
        _, _, _, al = hp[xx, yy]
        if al:
            hp[xx, yy] = (col[0], col[1], col[2], al)

# 4. smoked-dark background (vertical gradient, no glow — the steer is the hero).
bg = Image.new("RGB", (S, S), (0x16, 0x10, 0x0B)); bp = bg.load()
for y in range(S):
    t = y / S
    r = int(0x2A * (1 - t) + 0x12 * t)
    g = int(0x20 * (1 - t) + 0x0C * t)
    b = int(0x17 * (1 - t) + 0x08 * t)
    for x in range(S):
        bp[x, y] = (r, g, b)
canvas = bg.convert("RGBA")

# 5. place the head centered, ~74% of the canvas by its larger side.
scale = (S * 0.74) / max(head.size)
nw, nh = int(head.size[0] * scale), int(head.size[1] * scale)
head = head.resize((nw, nh), Image.LANCZOS)
canvas.alpha_composite(head, ((S - nw) // 2, (S - nh) // 2))

canvas.convert("RGB").save(OUT, "PNG")
print("wrote", OUT, canvas.size)
