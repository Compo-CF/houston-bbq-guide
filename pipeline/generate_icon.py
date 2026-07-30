#!/usr/bin/env python3
"""Generate the 1024x1024 App Store icon (opaque, no alpha) for Houston BBQ Guide.
Field-guide 'smoked' look: warm charcoal ground, ember glow, a bold flame emblem."""
from PIL import Image, ImageDraw
import math, os

S = 1024
img = Image.new("RGB", (S, S), (0x16, 0x10, 0x0B))
px = img.load()

# vertical smoked gradient + warm glow toward top
for y in range(S):
    t = y / S
    r = int(0x2A * (1 - t) + 0x14 * t)
    g = int(0x20 * (1 - t) + 0x0E * t)
    b = int(0x17 * (1 - t) + 0x09 * t)
    for x in range(S):
        px[x, y] = (r, g, b)

# radial ember glow behind the flame
glow = Image.new("RGB", (S, S), (0, 0, 0))
gd = glow.load()
cx, cy = S * 0.5, S * 0.46
for y in range(S):
    for x in range(S):
        d = math.hypot(x - cx, y - cy) / (S * 0.5)
        f = max(0.0, 1.0 - d)
        f = f * f
        gd[x, y] = (int(0xE2 * f), int(0x62 * f), int(0x2F * f))
img = Image.blend(img, Image.eval(glow, lambda v: v), 0.0)  # keep base
# composite glow additively-ish
base = img.load()
for y in range(S):
    for x in range(S):
        r, g, b = base[x, y]
        gr, gg, gb = gd[x, y]
        base[x, y] = (min(255, r + gr // 2), min(255, g + gg // 2), min(255, b + gb // 2))

draw = ImageDraw.Draw(img)

def flame(cx, cy, w, h, colors):
    """Draw a filled flame: pointed licking tip, rounded bulb base."""
    R = w / 2
    top_y = cy - h / 2
    bulb_cy = cy + h / 2 - R        # center of the rounded base
    left, right = [], []
    steps = 90
    for i in range(steps + 1):
        t = i / steps               # 0 = tip, 1 = top of bulb
        y = top_y + t * (bulb_cy - top_y)
        env = t ** 0.62             # 0 at tip → 1 at base, tapering
        curl = 0.10 * math.sin(t * math.pi) * (1 - t)   # slight S at the tip
        half = R * env
        left.append((cx - half + curl * w, y))
        right.append((cx + half + curl * w, y))
    # rounded base: semicircle sweeping from right side under to left side
    arc = []
    for i in range(41):
        a = i / 40 * math.pi         # 0 → pi (right, down, left)
        arc.append((cx + R * math.cos(a) + 0.0, bulb_cy + R * math.sin(a)))
    poly = left + arc + right[::-1]
    draw.polygon(poly, fill=colors)

# outer ember flame
flame(S * 0.5, S * 0.5, S * 0.42, S * 0.62, (0xE2, 0x62, 0x2F))
# inner amber flame
flame(S * 0.5, S * 0.54, S * 0.24, S * 0.40, (0xE8, 0xA5, 0x4A))
# hot core
flame(S * 0.5, S * 0.58, S * 0.11, S * 0.22, (0xF3, 0xD9, 0x9A))

out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "HoustonBBQGuide", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png")
img.save(out, "PNG")
print("wrote", out, img.size)
