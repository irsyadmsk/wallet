"""Google Play phone screenshots (1080x2160) of the demo build.

    flutter build web --release --dart-define=WALLET_DEMO=true -o <dir>
    python tool/store_screenshots.py <dir>

Serves <dir> locally, drives it with headless Chromium at a phone size and
saves docs/play-store/screenshot-*.png. Demo data only — nothing personal.
"""
import functools
import http.server
import sys
import threading

from playwright.sync_api import sync_playwright

root = sys.argv[1]
server = http.server.ThreadingHTTPServer(
    ('127.0.0.1', 8790), functools.partial(http.server.SimpleHTTPRequestHandler, directory=root))
threading.Thread(target=server.serve_forever, daemon=True).start()

OUT = 'docs/play-store'
W, H = 412, 824          # 2:1, Play's maximum aspect ratio
SCALE = 1080 / W          # -> 1080 x 2160


def shots(page, scheme):
    def tap(label):
        # Flutter web exposes tappables as role=button whose text starts with
        # their label; click the centre of the first match.
        box = page.evaluate("""(label) => {
            const el = [...document.querySelectorAll('[role="button"]')]
                .find(e => e.innerText.trim().startsWith(label));
            if (!el) return null;
            const r = el.getBoundingClientRect();
            return {x: r.x + r.width / 2, y: r.y + r.height / 2};
        }""", label)
        if box is None:
            raise RuntimeError(f'button {label!r} not found')
        page.mouse.click(box['x'], box['y'])
        page.wait_for_timeout(1800)

    def save(name):
        page.screenshot(path=f'{OUT}/screenshot-{name}.png')
        print('saved', name)

    page.goto('http://127.0.0.1:8790/')
    page.wait_for_timeout(9000)  # boot + seed demo ledger
    # Turn on Flutter's semantics tree so pages can be driven by label.
    page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
    page.wait_for_timeout(1000)
    save(f'1-beranda-{scheme}')
    tap('Transaksi')
    save(f'2-transaksi-{scheme}')
    tap('Laporan')
    save(f'3-laporan-{scheme}')
    tap('Lainnya')
    page.wait_for_timeout(600)
    tap('Kripto')
    save(f'4-kripto-{scheme}')
    tap('Lainnya')
    page.wait_for_timeout(600)
    tap('Akun')
    save(f'5-akun-{scheme}')


with sync_playwright() as p:
    browser = p.chromium.launch()
    for scheme in ('dark', 'light'):
        ctx = browser.new_context(viewport={'width': W, 'height': H}, device_scale_factor=SCALE,
                                  color_scheme=scheme, locale='id-ID')
        page = ctx.new_page()
        try:
            shots(page, scheme)
        except Exception as e:  # keep what was captured
            print('stopped:', e)
            page.screenshot(path=f'{OUT}/_debug-{scheme}.png')
        ctx.close()
    browser.close()
server.shutdown()
