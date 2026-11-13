"""Google Play feature graphic (1024x500) in the Wallet / ARUS colours.

    python tool/make_feature_graphic.py  ->  docs/play-store/feature-graphic.png

Uses the app icon already exported to docs/play-store/icon-512.png and the
bundled Plus Jakarta Sans, so the graphic cannot drift from the product.
"""
import math

from PIL import Image, ImageDraw, ImageFont

W, H, SS = 1024, 500, 3
INK = (0x19, 0x2E, 0x28)
DEEP = (0x0F, 0x1F, 0x1B)
PAPER = (0xF5, 0xF6, 0xF0)
MIST = (0xC8, 0xD6, 0xCF)
SAGE = (0x86, 0xB6, 0xA9)
CURRENTS = [(0x0C, 0x6C, 0x58), SAGE, (0xD9, 0xA4, 0x41), MIST]
F = 'assets/brand_fonts/PlusJakartaSans-'

s = lambda v: int(v * SS)
im = Image.new('RGB', (W * SS, H * SS), INK)
d = ImageDraw.Draw(im)

# Vertical ink gradient.
for y in range(H * SS):
    t = y / (H * SS)
    d.line([(0, y), (W * SS, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(INK, DEEP)))

# Drifting currents on the right: the same motif as the welcome loop.
for k in range(9):
    r = lambda n: (math.sin((k + 1) * 12.9898 + n * 78.233) * 43758.5453) % 1
    base, amp = 0.12 + k * 0.095, 0.03 + r(1) * 0.05
    pts = []
    for i in range(121):
        x = 0.42 + 0.6 * i / 120
        y = base + amp * math.sin(2 * math.pi * (1.4 * i / 120 + r(2))) * min(1, i / 30)
        pts.append((s(x * W), s(y * H)))
    colour = CURRENTS[k % len(CURRENTS)]
    # Each current on its own layer: drawn translucent directly, the joints
    # between segments overlap and read as dots.
    layer = Image.new('L', im.size, 0)
    ImageDraw.Draw(layer).line(pts, fill=round(70 + r(3) * 90), width=s(2 + r(4) * 4), joint='curve')
    im.paste(Image.new('RGB', im.size, colour), mask=layer)

# Fade the currents out towards the text.
fade = Image.new('L', (W * SS, H * SS), 0)
fd = ImageDraw.Draw(fade)
for x in range(W * SS):
    t = max(0.0, min(1.0, (x / (W * SS) - 0.40) / 0.22))
    fd.line([(x, 0), (x, H * SS)], fill=round(255 * (1 - t)))
flat = Image.new('RGB', im.size, INK)
fl = ImageDraw.Draw(flat)
for y in range(H * SS):
    t = y / (H * SS)
    fl.line([(0, y), (W * SS, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(INK, DEEP)))
im.paste(flat, mask=fade)
d = ImageDraw.Draw(im)

icon = Image.open('docs/play-store/icon-512.png').convert('RGBA').resize((s(132), s(132)), Image.LANCZOS)
mask = Image.new('L', icon.size, 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, icon.size[0] - 1, icon.size[1] - 1], s(30), fill=255)
im.paste(icon, (s(72), s(96)), mask)

title = ImageFont.truetype(F + 'SemiBold.ttf', s(84))
d.text((s(228), s(104)), 'Wallet', font=title, fill=PAPER)
sub = ImageFont.truetype(F + 'SemiBold.ttf', s(36))
d.text((s(74), s(268)), 'Buku kas pribadi & keluarga', font=sub, fill=PAPER)
small = ImageFont.truetype(F + 'Regular.ttf', s(25))
d.text((s(74), s(326)), 'Catat · rencanakan · pahami uang Anda', font=small, fill=MIST)

im.resize((W, H), Image.LANCZOS).save('docs/play-store/feature-graphic.png', optimize=True)
print('docs/play-store/feature-graphic.png')
