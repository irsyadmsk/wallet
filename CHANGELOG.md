# Catatan Versi Wallet

Ringkasan perubahan yang terasa bagi pengguna, terbaru di atas. Versi di sini
sama dengan `version:` di `pubspec.yaml` dan yang tampil di **Pengaturan**.
Nomor build (`versionCode`) naik otomatis setiap build dari GitHub Actions.

Teks singkat untuk kolom *"Yang baru di rilis ini"* di Play Console ada di
[`docs/play-store/whatsnew-id-ID.txt`](docs/play-store/whatsnew-id-ID.txt)
(maksimal 500 karakter).

## 1.3.0 — 27 September 2026

Rilis pertama untuk uji tertutup Google Play.

### Baru
- **Rekening dalam mata uang asing**: USD, SGD, MYR, SAR, EUR, JPY, dan
  lainnya (18 mata uang). Kurs dunia diperbarui otomatis tiap jam; total
  saldo, laporan, dan anggaran dihitung dalam rupiah dengan kurs terbaru.
- **Transfer beda mata uang**: jumlah yang diterima terisi dari kurs dan
  bisa disesuaikan dengan kurs bank.
- **Tabungan emas**: kelompok akun *Emas*, dicatat dalam **gram** atau
  **nilai rupiah**. Harga Antam per gram (jual & buyback) dari Galeri24
  (Pegadaian); emas dinilai dengan harga buyback.
- **Kartu "Harga hari ini"** di halaman Akun (emas per gram dan kurs).
- **Kartu rekening gaya dompet** di Beranda: kartu lain tampil sebagai tab
  berwarna; ketuk tab untuk memajukan, geser kartu depan untuk berganti.
  Urutannya diingat. Tombol *Tambah* ada di pojok kartu.
- **Cek saldo kartu e-money (NFC)** langsung dari tombol di atas Beranda.
- **Gestur satu tangan**: geser kiri/kanan untuk pindah halaman utama;
  geser ke atas pada bar bawah untuk membuka semua menu, geser ke bawah
  untuk menutup; geser transaksi ke kiri untuk hapus, ke kanan untuk
  mencatat lagi.
- **Kategori, sub-kategori, dan kelompok akun bisa diubah semua**: nama,
  emoji/ikon, warna, urutan, atau buat kelompok akun sendiri.

### Lebih nyaman
- **Isi nominal**: titik ribuan muncul saat mengetik, kursor tidak
  melompat, nominal dibaca ulang ("1,25 juta"), tombol cepat
  *000 / +10rb / +50rb / +100rb*, dan kalkulator di dalam kotak nominal.
- **Keyboard tidak lagi menutupi isian**; form naik perlahan mengikuti
  keyboard, tombol Simpan selalu terlihat, dan ringkasan transaksi tampil
  saat bagian atas form tertutup.
- **Scroll**: baris terakhir setiap halaman tidak lagi tertutup bar bawah.
- **Beranda lebih ringkas**: saldo total, masuk/keluar bulan ini, dan sisa
  anggaran dalam satu kartu; skor kesehatan keuangan pindah ke Laporan.

### Dihapus
- Impor dari Money Manager (`.mmbak`). Cadangan & pemulihan kini lewat
  berkas JSON di Pengaturan.

### Catatan
- Pasang versi ini di semua perangkat yang memakai akun yang sama. Versi
  lama belum mengenal mata uang asing dan emas dalam gram, sehingga akan
  membaca saldonya sebagai rupiah.

## 1.2.0 — 25 September 2026

- Sinkron awan dengan Supabase: masuk dengan email, data ikut di semua
  perangkat, buku kas keluarga bersama.
- Laporan cerdas, anggaran, target tabungan, utang & piutang, transaksi
  berulang, kalkulator zakat, pindai struk (OCR), portofolio kripto dengan
  harga live, cek saldo e-money (NFC).
- Navigasi HP model pil, tampilan tablet & desktop, kunci PIN.
- Kebijakan privasi (`/privasi`) dan penghapusan akun (`/hapus-akun`) untuk
  Google Play.
