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
- 📊 Dasbor, anggaran, target tabungan, utang & piutang, transaksi berulang, kalkulator (bagi tagihan, diskon, PPN), kalkulator zakat, pindai struk (OCR), impor `.mmbak`, ekspor CSV/JSON.
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
│   └── import/         # Impor .mmbak (Money Manager)
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
