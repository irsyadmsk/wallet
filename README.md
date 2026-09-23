# 💰 Wallet - Aplikasi Pencatat Keuangan Modern

Aplikasi pencatat keuangan (*Personal Finance & Money Management*) lintas platform yang dirancang dengan antarmuka modern, intuitif, dan arsitektur kode terstruktur berbasis **Flutter**, **GetX**, dan **Repository Pattern**.

> **Author / Creator:** **Muhammad Irsyad Sirojul Khoeir**  
> **Lisensi:** [MIT License](LICENSE)  
> **Status:** Siap Digunakan & Siap Integrasi Backend (*Backend-Ready*)

---

## 🌟 Fitur Utama

- 📊 **Dashboard Interaktif & Ringkas**:
  - Saldo gabungan multi-dompet dengan fitur intip saldo (*hide/show balance*).
  - Ringkasan arus kas bulanan (*Income vs Expense*).
  - Target Anggaran Bulanan (*Monthly Budget Tracker*) dengan indikator persentase real-time.
  - Aksi cepat: Tambah Pengeluaran, Tambah Pemasukan, dan Transfer antar-dompet.
  - Riwayat transaksi terkini dengan lencana kategori dan visual kontras.
- 💳 **Multi-Wallet / Dompet Fleksibel**:
  - Tambah, edit, dan hapus dompet rekening (BCA, Mandiri, BRI, BNI, GoPay, OVO, Dana, ShopeePay, Tunai, dll.).
  - Kartu gradien elegan dan pelacakan transaksi spesifik per dompet.
- 🏷️ **Kustomisasi Kategori**:
  - Tab kategori Pemasukan & Pengeluaran dengan ikon dan pemilih warna personal.
- 📝 **Pencatatan Transaksi Detail**:
  - Input nominal instan dengan format ribuan (*thousand separator*).
  - Dukungan multi-item rincian belanja dalam satu transaksi.
  - Transfer dana antar-dompet dengan validasi saldo otomatis.
  - Hapus transaksi dengan **otomatisasi pemulihan saldo (*balance reversal*)**.
- 🔍 **Pencarian & Filter Canggih**:
  - Filter rentang tanggal fleksibel (*Custom Date Range*).
  - Filter tipe transaksi, dompet, dan kategori.
  - Pencarian teks langsung (*live search*) untuk kategori, dompet, maupun nama rincian item.
- 📈 **Laporan Keuangan & Statistik (Analytics)**:
  - Grafik Donut (*Donut Chart*) proporsi pengeluaran dan pemasukan per kategori.
  - Kartu Arus Kas Bersih (*Net Cashflow*) & Rasio Tabungan (*Savings Rate %*).
  - Filter periode: Bulan Ini, Bulan Lalu, Tahun Ini, dan Semua Waktu.
- 🎯 **Target Anggaran Bulanan (Budgeting)**:
  - Atur limit pengeluaran bulanan dan pantau sisa kuota belanja dengan peringatan otomatis.
- 💾 **Manajemen Data & Ekspor**:
  - Ekspor seluruh riwayat transaksi ke format **CSV (Microsoft Excel / Google Sheets)**.
  - Backup & Restore database lokal dalam format JSON.
  - Penggantian tema warna utama aplikasi secara dinamis (*dynamic color palette*).

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
   ```

---

## 👨‍💻 Hak Cipta & Pengembang

Dibuat & dikembangkan oleh **Muhammad Irsyad Sirojul Khoeir**.  
Seluruh hak cipta dilindungi undang-undang di bawah lisensi MIT.
