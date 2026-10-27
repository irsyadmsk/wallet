# Catatan Versi Wallet

Ringkasan perubahan yang terasa bagi pengguna, terbaru di atas. Versi di sini
sama dengan `version:` di `pubspec.yaml` dan yang tampil di **Pengaturan**.
Nomor build (`versionCode`) ditetapkan eksplisit di pubspec dan harus meningkat untuk paket native baru.

Teks singkat untuk kolom *"Yang baru di rilis ini"* di Play Console ada di
[`docs/play-store/whatsnew-id-ID.txt`](docs/play-store/whatsnew-id-ID.txt)
(maksimal 500 karakter).

## 1.4.3 — kandidat lokal 23 Oktober 2026

- Tema terang/gelap dan font lokal mengikuti identitas terbaru Irsyads.
- Navigasi desktop ringkas dan mode fokus dengan tombol pemulihan.
- Pengaturan tema lebih mudah dipilih pada layar kecil dan teks besar.
- Daftar bulanan mendukung pencarian, filter belum selesai, dan kelompok yang dapat dilipat.
- Signing menggunakan identitas lama; kode native kandidat 10403 lebih tinggi dari maksimum 10400 yang teramati di Play. Belum dipublikasikan atau diuji update pada perangkat fisik.

## 1.4.2 — pembaruan web 22 Oktober 2026

Checklist bulanan, template, reserve pribadi dan impor terbatas dirilis pada web memakai build override 1.4.2+2. Ini bukan bukti pengiriman APK/AAB atau OTA 1.4.2.

## 1.4.1 — 20 Oktober 2026

Penyelarasan visual dan identitas dengan ekosistem irsyads.com.

### Tampilan & Identitas
- **Logo baru**: memakai logo pena Irsyads datar tanpa gradasi, hitam di atas putih untuk mode terang dan putih di atas hitam untuk mode gelap. Ikon launcher Android, adaptive icon, dan ikon web diperbarui.
- **Warna aksen ekosistem**: warna aksen utama diselaraskan ke `#134e4a` (Forest/Teal) senada dengan ubin Wallet di ekosistem irsyads.com.
- **Navigasi Ruang Irsyads**: pembaruan daftar ruang ekosistem ke 8 ruang utama dan tautan "Semua layanan" menuju `https://irsyads.com/apps`.

## 1.4.0 — 29 September 2026

Rilis perawatan untuk Google Play, berisi semua pembaruan 1–3 dari 1.3.1.

### Baru (dari pembaruan 1.3.1)
- **Pakai tanpa akun**; masuk/daftar kapan saja dan catatan ikut pindah.
- **Total dalam mata uang pilihan** (Rupiah, Dolar, emas, dll.).
- Gestur geser Beranda ⇄ Akun dan Laporan → Semua menu; form ditutup
  dengan menarik ke bawah.

### Teknis
- Komponen build Android diperbarui (Gradle 9.3.1, Android Gradle Plugin
  9.1.0, Kotlin 2.4.0) sebelum versi lama tidak didukung Flutter.
- Seluruh ikon ikut di aplikasi, sehingga pembaruan tanpa Play Store bisa
  memakai ikon apa pun.

## 1.3.1 — 28 September 2026

### Pembaruan 3 (tanpa Play Store)
- **Pakai tanpa akun**: ketuk *Mulai sekarang* di layar sambutan dan
  langsung mencatat. Catatan tersimpan di perangkat ini saja.
- Masuk/daftar kapan saja (Pengaturan › Akun, ikon awan di Beranda):
  catatan yang sudah ada ikut dipindahkan ke akun. Bila akun sudah berisi
  data, Anda memilih *Gabungkan* atau *Pakai data akun saja*.
- **Keluarga** dan cadangan cloud tetap butuh akun.
- Di web, pengingat bahwa catatan tanpa akun hanya tersimpan di browser.

### Pembaruan 2 (tanpa Play Store)
- **Total dalam mata uang pilihan**: ketuk *Saldo total* di Beranda atau
  *Total* di Akun untuk melihatnya dalam Rupiah, Dolar, emas (gram), dll.
  Pilihan diingat di HP ini.
- **Gestur geser**: dari Beranda geser ke kanan → Akun; dari Laporan geser
  lagi → Semua menu.
- Form (Transaksi baru, dll.) bisa **ditutup dengan menarik ke bawah**
  saat sudah di posisi paling atas.
- Kotak *Harga hari ini* pindah ke bagian bawah halaman Akun.

### Pembaruan 1 (tanpa Play Store)
- Pengaturan menampilkan nomor pembaruan, mis. *v1.3.1 (pembaruan 1)*,
  sehingga terlihat bila perbaikan kecil sudah terpasang otomatis.

### Baru
- **Tempel kartu e-money kapan saja**: saat Wallet tertutup, Android kini
  menampilkan Wallet di pilihan *"Tag NFC terdeteksi"* dan langsung membuka
  Cek Saldo Kartu.
- **Opsi "Masukkan ke total"** per akun (menu ⋮ di halaman Akun, atau saat
  mengubah akun). Akun yang dikeluarkan tetap tampil, tapi tidak dihitung
  di total saldo, kekayaan bersih, dan grafik laporan.
- Tombol **Atur kategori** di form transaksi, langsung ke tab Pemasukan
  atau Pengeluaran.

### Perbaikan
- Kategori pemasukan tidak lagi berisi kategori pengeluaran (form
  transaksi dan transaksi berulang) — daftar kini ikut berganti saat jenis
  diubah.
- Tombol **kembali** Android: dari halaman lain kembali ke Beranda; di
  Beranda tekan dua kali untuk keluar.
- Mode terang: tulisan pada tombol pilihan (filter transaksi, +10rb, dst.)
  dan ikon status bar kini terbaca.
- Halaman Akun: nama akun tidak lagi terpotong per huruf saat saldo
  panjang; tombol *Bayar* pindah ke menu ⋮.
- Transaksi Berulang: tampil jenis/kategori, frekuensi, akun, dan jumlah
  berwarna; tidak ada lagi dua tombol + yang bertumpuk.
- "Rp" dan angka di isian nominal kini sejajar.

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
