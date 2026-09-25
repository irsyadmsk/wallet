"""Generates every app icon from the Wallet mark (see lib/shared/ecosystem.dart:
letter "w", ink #E1E0CC on #19363B) using the bundled Inter Tight font.

    python tool/make_icons.py

Writes Android legacy + adaptive launcher icons, the web/PWA icons and
favicon, and the 512px Google Play store icon (docs/play-store/).
"""
import os
from PIL import Image, ImageDraw, ImageFont

BG = (0x19, 0x36, 0x3B)
INK = (0xE1, 0xE0, 0xCC)
ACCENT = (0x66, 0xD6, 0xBF)
FONT = 'assets/google_fonts/InterTight-SemiBold.ttf'


def mark(size, scale=0.62, bg=True, radius=0.0):
    """The "w*" mark centred on a square canvas. [scale] is the glyph height
    relative to the canvas; [radius] rounds the background corners."""
    ss = 4  # supersample for smooth edges
    s = size * ss
    im = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if bg:
        if radius > 0:
            d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * radius), fill=BG)
        else:
            d.rectangle([0, 0, s, s], fill=BG)
    font = ImageFont.truetype(FONT, int(s * scale))
    bbox = d.textbbox((0, 0), 'w', font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (s - w) / 2 - bbox[0] - s * 0.03
    y = (s - h) / 2 - bbox[1] + s * 0.02
    d.text((x, y), 'w', font=font, fill=INK)
    # Small accent asterisk, echoing the "W*" wordmark.
    star = ImageFont.truetype(FONT, int(s * scale * 0.42))
    sb = d.textbbox((0, 0), '*', font=star)
    d.text((x + w + s * 0.005, y + bbox[1] - sb[1] - s * 0.01), '*', font=star, fill=ACCENT)
    return im.resize((size, size), Image.LANCZOS)


def save(im, path, rgb=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (im.convert('RGB') if rgb else im).save(path, optimize=True)
    print(path, im.size)


res = 'android/app/src/main/res'
legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for dpi, px in legacy.items():
    save(mark(px, radius=0.22), f'{res}/mipmap-{dpi}/ic_launcher.png')
    # Adaptive foreground: 108dp canvas, glyph inside the 66dp safe zone.
    save(mark(int(px * 108 / 48), scale=0.36, bg=False), f'{res}/mipmap-{dpi}/ic_launcher_foreground.png')

os.makedirs(f'{res}/mipmap-anydpi-v26', exist_ok=True)
with open(f'{res}/mipmap-anydpi-v26/ic_launcher.xml', 'w', encoding='utf-8', newline='\n') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''')
with open(f'{res}/values/ic_launcher_background.xml', 'w', encoding='utf-8', newline='\n') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#19363B</color>
</resources>
''')

save(mark(192, radius=0.22), 'web/icons/Icon-192.png')
save(mark(512, radius=0.22), 'web/icons/Icon-512.png')
save(mark(192, scale=0.46), 'web/icons/Icon-maskable-192.png', rgb=True)
save(mark(512, scale=0.46), 'web/icons/Icon-maskable-512.png', rgb=True)
save(mark(64, radius=0.22), 'web/favicon.png')
# Play Store: 512x512, full-bleed square (Play applies its own mask).
save(mark(512), 'docs/play-store/icon-512.png', rgb=True)
