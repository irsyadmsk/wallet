// Wallet worker: serves the Flutter web build as static assets, plus one
// small API the app needs that can't be called straight from a browser.
//
// GET /api/emas — today's Antam gold price per gram (Indonesian retail),
// from Galeri24 (Pegadaian's gold gallery). Galeri24 sends no CORS header,
// so the web app can't fetch it directly; the phone app uses this too, so
// if the source changes only this file needs fixing. Cached for an hour.

const GALERI24 = 'https://galeri24.co.id/api/gold-prices';
const CACHE_SECONDS = 3600;

const cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, OPTIONS',
};

function json(body, status = 200, extra = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', ...cors, ...extra },
  });
}

/** yyyy-mm-dd in Asia/Jakarta, `daysAgo` days back. */
function jakartaDate(daysAgo = 0) {
  const t = new Date(Date.now() + 7 * 3600 * 1000 - daysAgo * 86400 * 1000);
  return t.toISOString().slice(0, 10);
}

/** Finds the 1-gram Antam bar in a Galeri24 results page. */
export function pickAntamGram(results) {
  const rows = (results || []).filter((r) => Number(r.denomination) === 1 && Number(r.sellingPrice) > 0);
  const antam = rows.find((r) => String(r.vendorName).trim().toUpperCase() === 'ANTAM') ||
    rows.find((r) => String(r.vendorName).toUpperCase().startsWith('ANTAM'));
  if (!antam) return null;
  return {
    sell: Math.round(Number(antam.sellingPrice)),
    buyback: Math.round(Number(antam.buybackPrice) || 0),
    date: antam.date || null,
    vendor: antam.vendorName,
  };
}

async function fetchGold() {
  // One day's list spans several pages of 20. Collect them all so the plain
  // "ANTAM" bar wins over variants (Retro, Non Pegadaian); walk back a few
  // days when today's list isn't published yet.
  for (let day = 0; day < 4; day++) {
    const rows = [];
    for (let page = 1; page <= 8; page++) {
      const url = `${GALERI24}?date=${jakartaDate(day)}&page=${page}`;
      const res = await fetch(url, { headers: { accept: 'application/json', 'user-agent': 'Mozilla/5.0 (Wallet)' } });
      if (!res.ok) break;
      const body = await res.json();
      rows.push(...(body.results || []));
      if (!body.next) break;
    }
    const found = pickAntamGram(rows);
    if (found) return found;
  }
  return null;
}

async function gold(request, ctx) {
  const cache = caches.default;
  const key = new Request(new URL('/api/emas', request.url).toString());
  const hit = await cache.match(key);
  if (hit) return hit;

  let found = null;
  try {
    found = await fetchGold();
  } catch (_) {
    found = null;
  }
  if (!found) return json({ error: 'Harga emas belum tersedia' }, 503, { 'cache-control': 'no-store' });

  const res = json(
    {
      sell: found.sell,
      buyback: found.buyback,
      date: found.date,
      source: `${found.vendor} · Galeri24 (Pegadaian)`,
    },
    200,
    { 'cache-control': `public, max-age=${CACHE_SECONDS}` },
  );
  ctx.waitUntil(cache.put(key, res.clone()));
  return res;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === '/api/emas') {
      if (request.method === 'OPTIONS') return new Response(null, { headers: cors });
      return gold(request, ctx);
    }
    return env.ASSETS.fetch(request);
  },
};
