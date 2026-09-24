# 💰 Wallet - Aplikasi Pencatat Keuangan Modern

Aplikasi pencatat keuangan (*Personal Finance & Money Management*) lintas platform yang dirancang dengan antarmuka modern, intuitif, dan arsitektur kode terstruktur berbasis **Flutter**, **GetX**, dan **Repository Pattern**.

> **Author / Creator:** **Muhammad Irsyad Sirojul Khoeir**  
> **Lisensi:** [MIT License](LICENSE)  
> **Status:** Siap Digunakan & Siap Integrasi Backend (*Backend-Ready*)

---

## 🌟 Fitur Utama

- 🔐 **Wajib masuk / daftar** — layar sambutan sinematik; akun Supabase dengan verifikasi email, lupa & ubah kata sandi. Data lokal dihapus dari perangkat saat keluar (setelah disinkronkan).
- 👨‍👩‍👧 **Akun keluarga** — buat keluarga, undang anggota dengan kode 8 karakter, dan semua anggota mencatat di satu buku kas yang tersinkron **realtime**. Setiap transaksi menyimpan nama pencatatnya.
- 🔄 **Sinkronisasi otomatis** — saat masuk, saat aplikasi dibuka kembali, beberapa detik setelah mencatat, tiap 3 menit, dan saat anggota lain mengubah data. Hanya baris yang berubah yang dikirim.
- 🧮 **Kalkulator baru** — ekspresi lengkap (urutan operasi, kurung, persen ala kalkulator ponsel), hasil langsung, riwayat, alat *bagi tagihan*, *diskon*, *+PPN 11%*, *+servis*, *bulatkan ribuan*, dan dukungan keyboard.
- 🧠 **Laporan cerdas & otomatis** — ringkasan naratif tiap bulan, perbandingan dengan bulan lalu, deteksi lonjakan kategori, proyeksi akhir bulan, deteksi langganan, pola belanja per hari, rincian per anggota keluarga, saran langkah berikutnya, dan salin laporan sebagai teks.
- 🏷️ **Kategori otomatis** — kategori dipilih sendiri dari riwayat saat Anda mengetik catatan.
- 🕌 **Kalkulator zakat** — penghasilan, mal, dan fitrah; terisi otomatis dari data Wallet; dasar hukum UU No. 23 Tahun 2011 dan PMA No. 52 Tahun 2014 jo. PMA No. 31 Tahun 2019.
- 📊 Dasbor, multi-akun & dompet, anggaran, target tabungan, utang & piutang, transaksi berulang, pindai struk (OCR), impor `.mmbak`, ekspor CSV/JSON, kunci PIN.
- 🎨 **Desain editorial** dengan gerak dinamis di setiap tombol — lihat [DESIGN.md](DESIGN.md).

---

## 🏗️ Arsitektur Proyek (Backend-Ready)

Proyek ini telah direstrukturisasi menggunakan **Repository Pattern** sehingga sangat mudah dihubungkan dengan berbagai backend (REST API Laravel, Node.js Nest/Express, Supabase, Firebase, Golang, dll.):

```
lib/
├── config/                  # Konfigurasi aplikasi & endpoint API backend
│   └── app_config.dart
├── data/                    # Data Layer
│   └── repositories/        # Abstraksi Repository (Local Hive / Remote API)
│       ├── i_transaction_repository.dart
│       ├── transaction_repository.dart
│       ├── i_wallet_repository.dart
│       ├── wallet_repository.dart
│       ├── i_category_repository.dart
│       └── category_repository.dart
├── models/                  # Entity Models dengan toJson() & fromJson()
│   ├── transaction_model/
│   ├── wallet_model/
│   ├── category_model/
│   └── user_model/
├── presentation/            # UI Layer (GetX Views & Controllers)
│   ├── dashboard/           # Halaman Utama & Widget Saldo
│   ├── history_transaction/ # Riwayat, Filter & Detail Transaksi
│   ├── analytics/           # Statistik & Grafik Donut
│   ├── category/            # Manajemen Kategori
│   ├── wallet/              # Manajemen Dompet
│   ├── form_expense/        # Form Pengeluaran
│   ├── form_income/         # Form Pemasukan
│   ├── form_transfer/       # Form Transfer
│   └── profile/             # Profil & Pengaturan
├── shared/                  # Reusable Themes & Widgets
│   ├── theme/               # Modern Theme & Typography
│   └── widget/              # Form Input & Icon Components
└── util/                    # Helper & Layanan Utilitas
    ├── budget_service/      # Perhitungan Target Budget
    └── db_service/          # Local Key-Value Storage
```

### 🔌 Cara Menghubungkan ke Backend REST API
Setiap model telah dilengkapi dengan fungsi serialisasi JSON lengkap:
- `TransactionModel.fromJson(Map<String, dynamic> json)` & `toJson()`
- `WalletModel.fromJson(Map<String, dynamic> json)` & `toJson()`
- `CategoryModel.fromJson(Map<String, dynamic> json)` & `toJson()`

Untuk beralih ke remote API, cukup buka `lib/config/app_config.dart`:
```dart
class AppConfig {
  static const bool useRemoteApi = true; // aktifkan mode remote
  static const String apiBaseUrl = "https://api.domainanda.com/v1";
}
```

---

## 🧰 Alat Pengembangan

Skill AI, server MCP (Context7, Supabase), Playwright CLI, Strix, dan SkillUI
didokumentasikan di [docs/TOOLING.md](docs/TOOLING.md).

---

## 🚀 Cara Menjalankan Aplikasi

### Prasyarat
- Flutter SDK (versi >= 3.8.1)
- Android Studio / VS Code / Cursor
- Emulator Android atau Web Browser (Chrome)

### Langkah-langkah
1. **Clone atau buka repositori:**
   ```bash
   git clone https://github.com/irsyadkhoeir/money-manager.git
   cd money-manager
   ```

2. **Pasang dependensi Flutter:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi:**
   ```bash
   # Menjalankan di Google Chrome (Web)
   flutter run -d chrome

   # Menjalankan di Windows Desktop
   flutter run -d windows

   # Menjalankan di Android Device / Emulator
   flutter run

   # Mode demo (tanpa login, data contoh lokal) untuk meninjau desain
   flutter run -d chrome --dart-define=WALLET_DEMO=true
   ```

---

## 👨‍💻 Hak Cipta & Pengembang

Dibuat & dikembangkan oleh **Muhammad Irsyad Sirojul Khoeir**.  
Seluruh hak cipta dilindungi undang-undang di bawah lisensi MIT.
