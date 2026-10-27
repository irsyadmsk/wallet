# wallet/worker — Worker wallet.irsyads.com

`index.js` dijalankan oleh Cloudflare Worker `wallet` (`../wrangler.jsonc`).

- Menyajikan hasil `flutter build web` dari `../build/web` sebagai Static Assets (SPA fallback).
- Satu API, `GET /api/emas`: harga emas Antam per gram dari Galeri24 (`https://galeri24.co.id/api/gold-prices`), di-cache 1 jam. Ada karena Galeri24 tidak mengirim header CORS. Aplikasi web dan Android sama-sama memakai endpoint ini, jadi bila sumbernya berubah cukup perbaiki berkas ini.
- Worker hanya dijalankan lebih dulu untuk `/api/*` (`run_worker_first`).

Deploy otomatis lewat `.github/workflows/deploy-web.yml` saat push ke `main`. Jangan menambahkan rahasia atau kunci Supabase service role ke worker ini.
