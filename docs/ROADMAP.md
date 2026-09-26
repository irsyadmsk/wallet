# Audit & Rencana Wallet

Diperbarui 25 September 2026. Dokumen ini mencatat bug yang sudah ditemukan dan
diperbaiki, kekurangan yang masih tersisa, serta rencana fitur berikutnya.
Urutannya dari fakta (apa yang terukur) ke kesimpulan (apa yang dikerjakan).

## 1. Bug yang sudah diperbaiki (24–25 September 2026)

| # | Gejala | Akar masalah (terukur) | Perbaikan |
|---|---|---|---|
| 1 | PIN 6 digit tidak pernah bisa membuka aplikasi | Layar kunci memakai panjang tetap 4 digit, pengaturan mengizinkan 4–6 | Panjang PIN disimpan (`salt:hash:panjang`); PIN lama dicoba di 4, 5, 6 digit |
| 2 | Impor Money Manager tidak jalan di web | Pembaca SQLite butuh `dart:ffi`; pemilih berkas di web tidak memberi *path* | SQLite WebAssembly (`web/sqlite3.wasm`) + pembacaan dari *bytes* |
| 3 | Aplikasi sangat berat setelah impor | Hash baris hasil tarikan dihitung dari data mentah server; Postgres `jsonb` mengurut ulang kunci sehingga semua baris selalu tampak berubah → unggah-unduh ulang tanpa henti | Hash dari bentuk lokal (`fromJson → toJson`); gema push sendiri dilewati |
| 4 | Setiap sinkron membekukan aplikasi beberapa detik | Tiap baris tarikan dicari dengan memindai seluruh kotak (n²: 5.000 baris ≈ 4 dtk di Dart VM) | Satu indeks id→key per batch, tulis dengan `putAll/addAll/deleteAll` |
| 5 | Data berlipat di cloud setelah impor ulang | "Ganti semua" tidak men-tombstone data lama; ID transaksi acak setiap impor | Tombstone sebelum mengganti; ID impor stabil `mm-<uid>` |
| 6 | Build APK merah sejak 24 September | `hive_generator` (analyzer lama) tidak mengenal elemen koleksi null-aware `?x` | Ditulis ulang `if (x != null) x` |
| 7 | Beranda menampilkan saldo lama setelah impor / pulihkan cadangan | Keduanya tidak memanggil `notifyDataChanged()` | Semua layar dimuat ulang setelah impor/pulihkan |
| 8 | Data yang dihapus lewat "Pulihkan cadangan" hidup lagi di perangkat lain | Pemulihan mengosongkan kotak tanpa tombstone | Memakai `tombstoneBeforeReplace` yang sama dengan impor |

Pencegahan: workflow **CI** baru (`.github/workflows/ci.yml`) menjalankan
build_runner, analisis, tes, dan build web di setiap PR — kasus #6 akan
tertangkap sebelum merge.

## 2. Kekurangan yang masih ada

Diurutkan dari dampak terbesar.

1. ~~Importer `.mmbak` belum diuji dengan berkas asli.~~ Fitur impor Money
   Manager dihapus (27 Sep 2026); cadangan & pemulihan kini hanya lewat JSON.
2. **Setiap sinkron masih menghitung hash semua baris lokal** (≈0,1 dtk per 5.000
   baris). Cukup ringan, tetapi bisa dihilangkan dengan penanda "kotor" dari
   `box.watch()` sehingga push hanya memeriksa baris yang benar-benar berubah.
3. **Gema Realtime:** setiap push memicu satu tarikan tambahan. Kini murah
   (baris yang sama dilewati), tetapi tetap satu permintaan jaringan.
4. **PIN tanpa batas percobaan.** Tambahkan jeda bertahap setelah 5 kali salah.
5. **Ikon emoji kategori di web** bergantung pada font Noto dari Google Fonts;
   tanpa internet tampil sebagai kotak. Solusi: ganti dengan ikon Material atau
   bundel subset emoji.
6. **Akun Wallet terpisah dari akun irsyads.com** (proyek Supabase berbeda).
   Pengguna perlu daftar dua kali.
7. **Repositori mencari baris dengan pemindaian linear** pada setiap edit
   tunggal. Tidak terasa untuk edit satu per satu, tetapi pola yang sama
   berbahaya bila dipakai untuk operasi massal.

## 3. Rencana fitur

### Prioritas 1 — melengkapi yang sudah ada
- **Anggaran per kategori dengan peringatan** (80% dan 100%), terhubung ke
  laporan cerdas.
- **Pengingat tagihan berulang** (notifikasi H-1) untuk transaksi berulang.
- **Ekspor laporan bulanan** ke PDF/Excel untuk arsip keluarga.
- **Hapus akun & semua data** dari aplikasi. Dasar hukum: hak subjek data untuk
  mengakhiri pemrosesan serta menghapus/memusnahkan data pribadinya, UU No. 27
  Tahun 2022 tentang Pelindungan Data Pribadi, Pasal 8.

### Prioritas 2 — keluarga
- **Uang saku anak**: anggaran per anggota keluarga dengan saldo sendiri.
- **Permintaan persetujuan**: anggota mengajukan pengeluaran besar, pemilik buku
  kas menyetujui.
- **Ringkasan mingguan keluarga** lewat email (Supabase Edge Function).

### Prioritas 3 — ekosistem irsyads.com
- **Satu akun untuk semua ruang** (irsyads.com, Academy, Ruang, Wallet) lewat
  proyek Supabase yang sama atau OAuth, sehingga pemilih "Ruang Irsyads"
  berpindah tanpa login ulang.
- **Target ibadah** (tabungan haji/umrah, kurban) sebagai templat target
  tabungan, melengkapi kalkulator zakat (UU No. 23 Tahun 2011 tentang
  Pengelolaan Zakat).
- **Instal sebagai aplikasi (PWA)** di laptop/ponsel dari wallet.irsyads.com.

## 4. Cara kerja rilis (otomatis)

1. Perubahan dikerjakan di cabang, lalu dibuka sebagai PR.
2. **CI** memeriksa PR: build_runner, analisis, tes, build web.
3. Setelah merge ke `main`:
   - **Deploy Web** membangun dan menayangkan wallet.irsyads.com (tes lebih
     dulu, lalu memastikan situs benar-benar menjawab).
   - **Build Android APK** membangun APK rilis; unduh dari bagian *Artifacts*.
4. Laptop disamakan dengan `tool/sinkron-lokal.ps1`.
