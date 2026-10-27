# 💰 Wallet — Buku Kas Pribadi & Keluarga

Aplikasi pencatat keuangan pribadi dan keluarga berbasis **Flutter**, **GetX**, **Hive**, dan **Supabase**. Bagian dari ekosistem [irsyads.com](https://irsyads.com).

> **Pembuat:** Muhammad Irsyad Sirojul Khoeir · **Lisensi:** [MIT](LICENSE)

---

## 📲 Pakai aplikasinya

| | Tautan |
|---|---|
| **Android (APK)** | [Releases › APK terbaru › `wallet.apk`](https://github.com/irsyadmsk/wallet/releases/tag/apk-latest) |
| **Web** | [wallet.irsyads.com](https://wallet.irsyads.com) |

**Memasang APK:** unduh `wallet.apk` di HP Android → buka filenya → izinkan *instal dari sumber ini* → **Instal**. APK berikutnya bisa langsung menimpa versi lama tanpa uninstall (ditandatangani dengan kunci yang sama). Data tersimpan di cloud, jadi aman bila aplikasi dipasang ulang.

APK dan web selalu diperbarui otomatis setiap ada perubahan di branch `main`.

---

## 🌟 Fitur

- 🔐 **Akun wajib** — masuk/daftar Supabase dengan verifikasi email, lupa & ubah kata sandi, kunci PIN.
- 👨‍👩‍👧 **Akun keluarga** — buat keluarga, undang dengan kode 8 karakter; semua anggota mencatat di satu buku kas yang tersinkron **realtime**, setiap transaksi menyimpan nama pencatatnya.
- 🔄 **Sinkronisasi otomatis** — saat masuk, saat aplikasi dibuka kembali, beberapa detik setelah mencatat, tiap 3 menit, dan saat anggota lain mengubah data. Hanya baris yang berubah yang dikirim.
- 🏦 **Akun & saldo** — bank, dompet digital, tunai, kartu kredit, dll.; tambah/ubah/hapus lewat tombol *Tambah* dan menu ⋮, akun terhapus bisa dipulihkan.
- ₿ **Portofolio kripto** — catat koin yang dimiliki, dinilai dengan harga Rupiah terkini dari CoinGecko, lengkap dengan perubahan 24 jam dan untung/rugi.
- 🧠 **Laporan cerdas** — ringkasan naratif bulanan, perbandingan, deteksi lonjakan & langganan, proyeksi akhir bulan, rincian per anggota keluarga.
- 📊 Dasbor, anggaran, target tabungan, utang & piutang, transaksi berulang, kalkulator (bagi tagihan, diskon, PPN), kalkulator zakat, pindai struk (OCR), ekspor CSV/JSON.
- 🎨 Desain editorial yang responsif (HP, tablet, desktop) — lihat [DESIGN.md](DESIGN.md).

---

## 🏗️ Arsitektur

```
lib/
├── app/            # Bootstrap, shell navigasi, sinkronisasi (SyncController), mode demo
├── config/         # Nama box Hive (AppBoxes) & konfigurasi
├── data/
│   ├── models/         # Model Hive + toJson/fromJson (typeId: hive_type_ids.dart)
│   ├── repositories/   # Akses box per entitas, lookup id O(1) lewat BoxIdIndex
│   ├── services/       # Ledger (saldo), laporan, zakat, harga kripto, sync ke Supabase
├── presentation/   # Halaman (view + controller GetX) per fitur
├── shared/         # Tema, widget bersama, scaffold responsif
└── util/           # Format uang, tanggal, dll.
```

- **Lokal dulu:** semua data di Hive (IndexedDB di web), jadi aplikasi tetap jalan offline.
- **Sinkronisasi:** setiap box Hive dicerminkan ke satu tabel Supabase (`id`, `user_id`, `data jsonb`, `updated_at`, `deleted_at`). Pull memakai `updated_at` dari jam server; push hanya baris yang berubah. Lihat `lib/data/services/sync/`.
- **Keluarga:** baris disimpan di bawah `user_id` pemilik buku kas; RLS `private.accessible_ledgers()` memberi akses ke anggota keluarga.

### Supabase

Proyek Supabase: **`wallet`**. Semua perubahan skema ada di [`supabase/migrations/`](supabase/migrations) dan nama filenya sama dengan versi yang tercatat di server. Menambah entitas yang disinkron: buat tabel dengan pola yang sama (lihat `20260925031823_crypto_holdings.sql`), daftarkan di `lib/data/services/sync/sync_registry.dart`, dan tambahkan ke daftar Realtime di `SyncController`.

---

## ⚙️ CI/CD

| Workflow | Kapan | Hasil |
|---|---|---|
| `ci.yml` | Setiap pull request | `flutter analyze`, `flutter test`, build web |
| `deploy-web.yml` | Push ke `main` | Build web → Cloudflare Workers → [wallet.irsyads.com](https://wallet.irsyads.com) |
| `build-apk.yml` | Push ke `main` | Tes + APK rilis → Release **APK terbaru** (`apk-latest`) |

Secret repositori yang dipakai: `CLOUDFLARE_API_TOKEN` (deploy web) dan `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (tanda tangan APK). **Simpan cadangan keystore** — tanpa kunci yang sama, APK baru tidak bisa memperbarui aplikasi yang sudah terpasang.

---

## 🛠️ Pengembangan

Prasyarat: Flutter SDK (Dart ≥ 3.8).

```bash
git clone https://github.com/irsyadmsk/wallet.git
cd wallet
flutter pub get
flutter run -d chrome     # web
flutter run               # Android
```

Mode demo (tanpa login, data contoh lokal, tidak disinkron):

```bash
flutter run -d chrome --dart-define=WALLET_DEMO=true
# + ±5.000 transaksi & 33 akun untuk uji performa:
flutter run -d chrome --dart-define=WALLET_DEMO=true --dart-define=WALLET_DEMO_BIG=true
```

Setelah mengubah model Hive, buat ulang adapter:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Sebelum membuka PR: `flutter analyze` dan `flutter test`. Alat bantu pengembangan (skill AI, MCP, Playwright) ada di [docs/TOOLING.md](docs/TOOLING.md).

---

Dibuat & dikembangkan oleh **Muhammad Irsyad Sirojul Khoeir** di bawah lisensi MIT.

---

## 🤖 Panduan untuk AI dan pengembang

**Status:** Wallet **dibekukan** — ubah kode hanya bila pemilik meminta pekerjaan Wallet secara khusus. Baca `AGENTS.md` (status rilis terbaru di bagian atas, bertanggal) dan `CHANGELOG.md` sebelum bekerja. Versi saat ini `1.4.3+10403` (`pubspec.yaml`); rilis web dan Play Alpha 23 Okt 2026 sudah memakai izin yang diberikan, jadi izin itu tidak berlaku untuk rilis berikutnya.

**Push ke `main` = rilis.** `deploy-web.yml` menayangkan wallet.irsyads.com dan `build-apk.yml` membangun/menandatangani APK (bisa juga patch Shorebird) secara otomatis. Jangan push, memicu workflow, upload Play Store, atau menjalankan migrasi tanpa persetujuan pemilik untuk rilis itu.

| Lokasi | Isi |
|---|---|
| `lib/app/` | `bootstrap.dart`, `money_manager_app.dart`, `shell_controller.dart`, **`sync_controller.dart`** (jadwal sinkron + Realtime), `demo_mode.dart`, `guest_mode.dart` |
| `lib/data/models/` | Model Hive. `typeId` terdaftar di `hive_type_ids.dart`; jangan memakai ulang/mengubah nomor yang ada (data pengguna rusak) |
| `lib/data/repositories/` | Akses box per entitas |
| `lib/data/services/` | `ledger_service.dart` (saldo), laporan, zakat, kripto (CoinGecko), OCR struk, NFC e-money, PIN, keluarga |
| `lib/data/services/sync/` | `sync_registry.dart` (daftar entitas yang disinkron), `sync_service.dart`, `ledger_merge.dart`, `tombstone_service.dart` |
| `lib/presentation/<fitur>/` | Halaman (view + controller GetX) per fitur |
| `packages/prepaidcard_reader/` | Plugin NFC kartu prabayar (fork lokal) |
| `worker/index.js` | Worker Cloudflare: menyajikan `build/web` + satu API `GET /api/emas` (harga emas Antam dari Galeri24, cache 1 jam) |
| `supabase/migrations/` | Skema proyek Supabase **`wallet`** (bukan proyek irsyads). Nama berkas = versi di server |
| `tool/` | Generator ikon (`make_icons.py` memanggil generator ikon di `../irsyads`), aset Play Store, `sinkron-lokal.ps1` |
| `docs/` | `BUILD_LOKAL.md`, `PLAY_STORE.md`, `SHOREBIRD.md`, `TOOLING.md`, `ROADMAP.md` + catatan bertanggal (riwayat) |

**Jangan:** membuat atau mengganti keystore (pembaruan APK butuh kunci yang sama), mengubah `applicationId`, uninstall/clear storage di perangkat pengguna, menebak nomor versi, atau menjalankan `dart fix` global. Validasi native di laptop 8 GB: pakai pengaturan heap kecil di `docs/2026-10-23_AG10_NATIVE_CONTINUATION.md`.

**Uji lokal:** `flutter analyze` dan `flutter test` (tes di `test/`).
