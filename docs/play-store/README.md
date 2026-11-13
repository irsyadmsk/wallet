# Bahan halaman Google Play

Semua bahan di folder ini dibuat dari **build demo** (data tiruan, bukan data
pribadi) dan siap diunggah ke Play Console › *Grow* › *Store presence* ›
*Main store listing*. Diperbarui 13 November 2026 untuk versi 1.5.0.

## Berkas mana untuk kolom mana

| Kolom di Play Console | Berkas | Ukuran | Syarat Play |
|---|---|---|---|
| Ikon aplikasi | `icon-512.png` | 512×512 | PNG 32-bit, maks. 1 MB |
| Grafik fitur | `feature-graphic.png` | 1024×500 | PNG/JPEG tanpa alfa |
| Screenshot ponsel | `listing-1…8-*.png` | 1080×1920 (9:16) | 2–8 gambar, sisi 320–3840 px, PNG/JPEG tanpa alfa |
| Video | tautan YouTube dari `web/media/playstore.mp4` | 1920×1080, 29 detik | Lihat di bawah |
| Deskripsi singkat | `short-description-id-ID.txt` | ≤ 80 karakter | |
| Deskripsi lengkap | `description-id-ID.txt` | ≤ 4.000 karakter | |
| Yang baru di rilis ini | `whatsnew-id-ID.txt` | ≤ 500 karakter | Diisi saat membuat rilis |

Urutan screenshot yang disarankan mengikuti nomornya: Beranda, Rencana
Bulanan, rencana dan buku kas, kalender tagihan, akun, catat, laporan, target.

`store-1…8-*.png` adalah set cadangan bergaya terang (pembuka berlogo, slide
kepercayaan, lalu fitur). Pakai salah satu set, jangan dicampur.
`screenshot-*.png` adalah tangkapan polos lama dari sebelum penyegaran
tampilan; jangan dipakai untuk halaman toko versi ini.

## Video

Play Console tidak menerima berkas video; kolom *Video* hanya menerima
**URL YouTube**. Langkahnya:

1. Unggah `web/media/playstore.mp4` ke kanal YouTube pemilik aplikasi.
2. Visibilitas **Publik** atau **Tidak publik** (*unlisted*). Jangan *Pribadi*.
3. Matikan monetisasi/iklan pada video itu dan jangan beri batasan usia;
   video beriklan atau berbatas usia ditolak Play.
4. Tempel URL-nya di kolom *Video*, lalu simpan.

Judul dan deskripsi YouTube yang bisa dipakai:

> **Wallet — Buku Kas Pribadi & Keluarga**
>
> Catat pemasukan dan pengeluaran, rencanakan gaji bulanan, pantau tagihan
> jatuh tempo, dan lihat semua saldo bank serta dompet digital di satu
> tempat. Tanpa iklan. https://wallet.irsyads.com

Video itu berupa gambar gerak dari desain aplikasi dengan angka tiruan, bukan
rekaman layar. Play mengizinkannya, tetapi video harus menggambarkan aplikasi
apa adanya; perbarui bila tampilan berubah banyak. `web/media/tur.mp4`
(potret) cocok untuk media sosial, bukan untuk kolom ini.

## Membuat ulang

```bash
flutter build web --release --no-web-resources-cdn --dart-define=WALLET_DEMO=true -o build/demo-web
```

```bash
python tool/store_listing.py build/demo-web
```

```bash
python tool/make_feature_graphic.py
```

`store_listing.py` memerlukan `pip install playwright pillow`. Bila peramban
Playwright tidak bisa diunduh, arahkan ke Chromium yang sudah terpasang lewat
variabel `WALLET_CHROMIUM`. Video dirender dari `motion/` (lihat
`motion/README.md`).
