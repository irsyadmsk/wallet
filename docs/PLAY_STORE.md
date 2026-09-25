# Rencana rilis Wallet ke Google Play

Status per 25 September 2026. Paket aplikasi: **`com.irsyads.wallet`**.

## 0. Sudah disiapkan (tanpa akun developer)

| Kebutuhan Play | Status |
|---|---|
| Android App Bundle (`.aab`) bertanda tangan | ✅ CI membangun `wallet.aab` di Release **APK terbaru** setiap push ke `main` |
| Kunci unggah tetap | ✅ Keystore `wallet-release.jks` (secret `ANDROID_KEYSTORE_*`), cadangan di `C:\Users\T6N0CV02S35823C\.wallet-signing\` |
| `versionCode` naik tiap build | ✅ = nomor run GitHub Actions |
| Ikon aplikasi (adaptif + 512 px) | ✅ `docs/play-store/icon-512.png`, dibuat oleh `tool/make_icons.py` |
| Kebijakan privasi (URL publik) | ✅ `https://wallet.irsyads.com/privasi.html` (tayang setelah merge) |
| Hapus akun di dalam aplikasi | ✅ Pengaturan › Zona bahaya › Hapus akun permanen |
| URL permintaan hapus akun | ✅ `https://wallet.irsyads.com/hapus-akun.html` |
| Izin minimal | ✅ Internet, kamera (pindai struk), NFC (e-money), baca penyimpanan hanya ≤ Android 12 |
| Target SDK terbaru | ✅ Mengikuti Flutter 3.47 (API 35+) |

**Yang masih perlu Anda siapkan sebelum mengisi Play Console:**

1. **Email dukungan yang aktif.** Kebijakan privasi dan halaman hapus akun memakai `privasi@irsyads.com`. Buat kotak surat/alias itu (misalnya lewat Cloudflare Email Routing ke Gmail Anda), atau beri tahu alamat lain supaya halaman diganti.
2. **Screenshot**: minimal 2, disarankan 4–8, ukuran HP (1080×1920 atau 1080×2400). Bisa diambil dari mode demo (`--dart-define=WALLET_DEMO=true`) supaya tidak memuat data pribadi.
3. **Feature graphic** 1024×500 (spanduk di halaman toko).
4. **Akun uji untuk tim review Google**, karena aplikasi wajib login. Buat satu akun Supabase khusus (misalnya `review@irsyads.com`) dan isi dengan data contoh.

## 1. Buat akun Google Play Console (Anda)

1. Daftar di <https://play.google.com/console/signup> memakai akun Google yang akan menjadi pemilik aplikasi.
2. Pilih jenis akun:
   - **Pribadi**: paling cepat. Wajib *closed testing* dengan **minimal 12 penguji selama 14 hari berturut-turut** sebelum bisa rilis produksi.
   - **Organisasi**: butuh nomor D-U-N-S (gratis, 1–4 minggu), tapi tidak wajib 12 penguji.
3. Bayar biaya pendaftaran sekali **US$25** (± Rp 400 ribu) dengan kartu kredit/debit.
4. Verifikasi identitas (KTP) dan nomor telepon. Proses ini bisa memakan beberapa hari.

> Kirimkan ke saya setelah akun aktif: email akun developer. Saya tidak butuh kata sandi. Tambahkan saya lewat *Users & permissions* atau lakukan langkah di Console sendiri dengan panduan di bawah.

## 2. Buat aplikasi di Console

- Nama: **Wallet — Buku Kas Keluarga** (maks. 30 karakter).
- Bahasa default: Indonesia. Jenis: Aplikasi. Gratis.
- **Play App Signing: aktifkan (default).** Kunci `wallet-release.jks` menjadi *upload key*; Google menyimpan kunci penandatanganan akhir.

## 3. Isi halaman toko

| Kolom | Isi yang disarankan |
|---|---|
| Deskripsi singkat (80) | Catat keuangan pribadi & keluarga, sinkron otomatis, laporan cerdas. |
| Deskripsi lengkap | Ambil dari bagian **Fitur** di README: akun keluarga realtime, akun & saldo, anggaran, laporan cerdas, zakat, kripto, pindai struk. |
| Ikon | `docs/play-store/icon-512.png` |
| Kategori | Keuangan |
| Email kontak | email dukungan dari langkah 0 |
| Situs | `https://wallet.irsyads.com` |
| Kebijakan privasi | `https://wallet.irsyads.com/privasi.html` |

## 4. Formulir wajib (App content)

- **Akses aplikasi**: "Semua fungsi butuh login", lalu isi akun uji dari langkah 0.
- **Iklan**: Tidak ada iklan.
- **Rating konten**: kuesioner IARC (aplikasi keuangan tanpa konten sensitif, hasilnya "Semua umur").
- **Target audiens**: 18+ (menghindari persyaratan Families).
- **Keamanan data (Data safety)**:
  - Dikumpulkan: *Email*, *Nama*, *Info keuangan lain (catatan transaksi)*. Tujuan: fungsionalitas aplikasi dan manajemen akun. Tidak dibagikan ke pihak ketiga. Dienkripsi saat transit.
  - Pengguna bisa meminta penghapusan: **Ya**, dengan URL `https://wallet.irsyads.com/hapus-akun.html`.
  - Foto struk dan data NFC diproses di perangkat, tidak dikumpulkan.
- **Aplikasi keuangan (Financial features)**: pilih *"Aplikasi tidak menyediakan layanan keuangan"*. Wallet hanya mencatat dan tidak memindahkan uang. Harga kripto hanya informasi.
- **Pemerintah / berita / kesehatan**: Tidak.

## 5. Uji tertutup lalu produksi

1. *Testing › Closed testing* → buat track, unggah `wallet.aab` dari Release **APK terbaru**.
2. Undang penguji lewat email atau Google Group. Akun pribadi wajib **≥ 12 penguji aktif selama 14 hari**; keluarga dan teman bisa jadi penguji.
3. Setelah 14 hari: ajukan *Apply for production*, isi pertanyaan singkat tentang hasil uji, lalu tunggu review (biasanya 1–7 hari).
4. Rilis produksi bertahap (misalnya 20% → 100%).

## 6. Otomatisasi setelah akun ada (opsional, saya kerjakan)

- Buat *service account* Google Cloud dengan akses Play Console, simpan sebagai secret `PLAY_SERVICE_ACCOUNT_JSON`.
- Workflow mengunggah `wallet.aab` otomatis ke track *internal/closed* setiap push ke `main`.

## 7. Perkiraan biaya & waktu

| Item | Biaya | Waktu |
|---|---|---|
| Pendaftaran Play Console | US$25 sekali | 1–3 hari verifikasi |
| Email dukungan (Cloudflare Email Routing) | gratis | 10 menit |
| Uji tertutup 12 penguji (akun pribadi) | gratis | 14 hari |
| Review produksi | gratis | 1–7 hari |
| **Total** | **± US$25** | **± 3 minggu** (akun pribadi) |

## 8. Setelah rilis

- Pantau *Android vitals* (crash/ANR) di Play Console.
- Pengguna APK dari GitHub **tidak otomatis pindah** ke versi Play. Versi Play ditandatangani ulang oleh Google, jadi mereka perlu uninstall APK lalu pasang dari Play Store sekali. Data aman di cloud.
