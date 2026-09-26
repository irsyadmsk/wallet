"""Google Play listing images: app screens in a phone frame with a headline.

    flutter build web --release --dart-define=WALLET_DEMO=true -o <dir>
    python tool/store_listing.py <dir>

1. Serves <dir> locally and captures the demo build with headless Chromium
   (light theme, phone size) into docs/play-store/raw/.
2. Composes 1080x1920 (9:16) listing images docs/play-store/listing-*.png:
   brand-green backdrop, headline + subline in the app's own fonts, the
   screen in a phone frame. Demo data only — nothing personal.
"""
import functools
import http.server
import os
import sys
import threading

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = 'docs/play-store'
RAW = f'{OUT}/raw'
FONTS = 'assets/google_fonts'
W, H = 412, 824          # phone viewport, 1:2
SCALE = 1080 / W          # -> 1080 x 2160 captures

# (file, headline, subline). Headlines stay short: they're read at thumbnail size.
SLIDES = [
    ('beranda', 'Semua uang keluarga,\nsatu tempat', 'Saldo, pemasukan & anggaran bulan ini\nsekali lihat'),
    ('kartu', 'Kartu rekening\nala dompet', 'Ketuk atau geser untuk berganti rekening'),
    ('catat', 'Catat dalam\nhitungan detik', 'Titik ribuan otomatis, tombol cepat\n& kalkulator bawaan'),
    ('akun', 'Dolar & emas,\nnilai hari ini', 'Kurs dunia dan harga Antam per gram,\ndiperbarui otomatis'),
    ('laporan', 'Laporan yang\nmudah dipahami', 'Ke mana uang pergi, dan apa\nlangkah berikutnya'),
    ('kategori', 'Rapi sesuai\ncara Anda', 'Kategori & kelompok akun\nbisa diubah sesukanya'),
]


def capture(root):
    from playwright.sync_api import sync_playwright

    server = http.server.ThreadingHTTPServer(
        ('127.0.0.1', 8791), functools.partial(http.server.SimpleHTTPRequestHandler, directory=root))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    os.makedirs(RAW, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch()
        ctx = browser.new_context(viewport={'width': W, 'height': H}, device_scale_factor=SCALE,
                                  color_scheme='light', locale='id-ID')
        page = ctx.new_page()

        def tap(label):
            box = page.evaluate("""(label) => {
                const el = [...document.querySelectorAll('[role="button"], [role="tab"]')]
                    .find(e => (e.innerText || e.getAttribute('aria-label') || '').trim().startsWith(label));
                if (!el) return null;
                const r = el.getBoundingClientRect();
                return {x: r.x + r.width / 2, y: r.y + r.height / 2};
            }""", label)
            if box is None:
                raise RuntimeError(f'button {label!r} not found')
            page.mouse.click(box['x'], box['y'])
            page.wait_for_timeout(1600)

        def save(name):
            # Park the pointer off-screen so no hover tooltip shows up.
            page.mouse.move(W - 2, 2)
            page.wait_for_timeout(400)
            page.screenshot(path=f'{RAW}/{name}.png')
            print('captured', name)

        page.goto('http://127.0.0.1:8791/')
        page.wait_for_timeout(10000)  # boot, seed demo ledger, fetch rates
        page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
        page.wait_for_timeout(1000)
        save('beranda')

        page.mouse.move(W / 2, H / 2)
        for _ in range(6):  # wheel steps animate; repeat until the end
            page.mouse.wheel(0, 1500)
            page.wait_for_timeout(700)
        page.wait_for_timeout(1500)
        save('kartu')
        page.mouse.wheel(0, -3000)
        page.wait_for_timeout(800)

        tap('Catat transaksi')
        page.wait_for_timeout(800)
        page.keyboard.type('1250000', delay=60)
        page.wait_for_timeout(900)
        save('catat')
        page.keyboard.press('Escape')
        page.wait_for_timeout(1000)

        tap('Lainnya')
        tap('Akun')
        page.wait_for_timeout(2500)
        save('akun')

        tap('Laporan')
        page.wait_for_timeout(1500)
        save('laporan')

        tap('Lainnya')
        tap('Kategori')
        save('kategori')

        ctx.close()
        browser.close()
    server.shutdown()


# ---------------------------------------------------------------- compose

CW, CH = 1080, 1920
FOREST_TOP = (27, 58, 62)
FOREST_BOTTOM = (13, 32, 35)
CREAM = (236, 235, 221)
MINT = (127, 200, 162)


def font(name, size):
    return ImageFont.truetype(f'{FONTS}/{name}', size)


def backdrop():
    img = Image.new('RGB', (CW, CH))
    d = ImageDraw.Draw(img)
    for y in range(CH):
        t = y / CH
        d.line([(0, y), (CW, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(FOREST_TOP, FOREST_BOTTOM)))
    # One soft light behind the phone gives depth without noise.
    glow = Image.new('L', (CW, CH), 0)
    ImageDraw.Draw(glow).ellipse([CW * 0.1, CH * 0.38, CW * 0.9, CH * 1.05], fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    img.paste(Image.new('RGB', (CW, CH), (60, 120, 110)), mask=glow)
    return img


def rounded(im, r):
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], r, fill=255)
    out = Image.new('RGBA', im.size)
    out.paste(im, mask=mask)
    return out


def phone(screen, width):
    bezel = 18
    sw = width - 2 * bezel
    shot = screen.convert('RGB').resize((sw, round(sw * screen.height / screen.width)), Image.LANCZOS)
    shot = rounded(shot, 58)
    fw, fh = width, shot.height + 2 * bezel
    frame = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle([0, 0, fw - 1, fh - 1], 74, fill=(10, 14, 14, 255))
    ImageDraw.Draw(frame).rounded_rectangle([3, 3, fw - 4, fh - 4], 72, outline=(70, 82, 80, 255), width=2)
    frame.alpha_composite(shot, (bezel, bezel))
    return frame


def compose(i, name, title, sub):
    img = backdrop().convert('RGBA')
    d = ImageDraw.Draw(img)
    title_font = font('InterTight-Bold.ttf', 88)
    sub_font = font('DMSans-Medium.ttf', 40)

    y = 120
    for line in title.split('\n'):
        w = d.textlength(line, font=title_font)
        d.text(((CW - w) / 2, y), line, font=title_font, fill=CREAM)
        y += 100
    y += 18
    for line in sub.split('\n'):
        w = d.textlength(line, font=sub_font)
        d.text(((CW - w) / 2, y), line, font=sub_font, fill=MINT)
        y += 54

    screen = Image.open(f'{RAW}/{name}.png')
    ph = phone(screen, 780)
    top = y + 60
    # Soft shadow under the phone.
    shadow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [(CW - ph.width) / 2 + 10, top + 30, (CW + ph.width) / 2 - 10, top + ph.height + 30], 74, fill=(0, 0, 0, 150))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(40)))
    img.alpha_composite(ph, ((CW - ph.width) // 2, top))  # bottom runs off the edge on purpose

    path = f'{OUT}/listing-{i + 1}-{name}.png'
    img.convert('RGB').save(path, optimize=True)
    print('saved', path)


if __name__ == '__main__':
    if len(sys.argv) > 1:
        capture(sys.argv[1])
    for i, (name, title, sub) in enumerate(SLIDES):
        compose(i, name, title, sub)
