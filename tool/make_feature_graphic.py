"""Google Play feature graphic (1024x500) in the Wallet mark's colours.

    python tool/make_feature_graphic.py  ->  docs/play-store/feature-graphic.png
"""
from PIL import Image, ImageDraw, ImageFont

W, H, SS = 1024, 500, 3
BG = (0x19, 0x36, 0x3B)
INK = (0xE1, 0xE0, 0xCC)
ACCENT = (0x66, 0xD6, 0xBF)
MUTED = (0xA9, 0xB8, 0xB0)
F = 'assets/google_fonts/'

im = Image.new('RGB', (W * SS, H * SS), BG)
d = ImageDraw.Draw(im)
s = lambda v: int(v * SS)

# Soft accent circle, bottom right.
d.ellipse([s(700), s(250), s(1180), s(730)], fill=(0x1F, 0x44, 0x49))
d.ellipse([s(790), s(-160), s(1100), s(150)], fill=(0x1D, 0x3E, 0x43))

# Mark tile.
d.rounded_rectangle([s(72), s(150), s(272), s(350)], radius=s(44), fill=INK)
mark = ImageFont.truetype(F + 'InterTight-SemiBold.ttf', s(150))
bb = d.textbbox((0, 0), 'w', font=mark)
d.text((s(172) - (bb[2] - bb[0]) / 2 - bb[0] - s(8), s(250) - (bb[3] - bb[1]) / 2 - bb[1]), 'w', font=mark, fill=BG)
star = ImageFont.truetype(F + 'InterTight-SemiBold.ttf', s(64))
d.text((s(222), s(170)), '*', font=star, fill=(0x1F, 0x8A, 0x70))

title = ImageFont.truetype(F + 'InterTight-SemiBold.ttf', s(92))
d.text((s(318), s(128)), 'Wallet', font=title, fill=INK)
d.text((s(318) + d.textlength('Wallet', font=title) + s(6), s(122)), '*', font=ImageFont.truetype(F + 'InterTight-SemiBold.ttf', s(52)), fill=ACCENT)

sub = ImageFont.truetype(F + 'DMSans-Medium.ttf', s(36))
d.text((s(322), s(250)), 'Buku kas pribadi & keluarga', font=sub, fill=INK)
small = ImageFont.truetype(F + 'DMSans-Regular.ttf', s(26))
d.text((s(322), s(306)), 'Catat · sinkron otomatis · laporan cerdas', font=small, fill=MUTED)

im.resize((W, H), Image.LANCZOS).save('docs/play-store/feature-graphic.png', optimize=True)
print('docs/play-store/feature-graphic.png')
