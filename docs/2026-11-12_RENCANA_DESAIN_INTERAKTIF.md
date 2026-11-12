# Rencana perbaikan desain Wallet — interaktif, animatif, elegan

12 November 2026 · status: **rencana, menunggu persetujuan pemilik** · belum ada
kode aplikasi yang diubah oleh dokumen ini.

Urutan dokumen ini induktif: temuan terukur pada kode → simpulan → rancangan →
pembagian cabang dan model → gerbang uji.

## 1. Temuan pada kode saat ini

| # | Fakta (berkas) | Akibat bagi pengguna |
|---|---|---|
| 1 | `lib/presentation/monthly/monthly_plan_view.dart` (867 baris) masih satu `StatefulWidget` berisi daftar dan formulir | Fungsi gaji, bonus, langganan, tabungan, dan dana bergulir sudah ada, tetapi tampil sebagai tabel isian; tidak terasa "ARUS" |
| 2 | `AppMotion.skipPageMotion` mematikan animasi halaman di web karena biaya CanvasKit | Web, kanal yang paling sering dipakai, nyaris tanpa gerak |
| 3 | Primitif gerak sudah tersedia (`Pressable`, `Reveal`, `AnimatedMoney`, `InertiaTile`, `PillTabs`) tetapi hanya dipakai di sebagian layar | Bahasa gerak tidak konsisten antarlayar |
| 4 | `AccountGroupType` tidak memiliki kelompok dompet digital; GoPay, OVO, DANA, LinkAja, ShopeePay hanya hadir sebagai logo di `bank_logo_picker.dart` | Dompet digital terpaksa dicatat sebagai "Bank" atau "Lainnya" |
| 5 | Tidak ada logo Bank DKI/Bank Jakarta maupun JakOne; pembaca NFC (`emoney_nfc_service.dart`) hanya mengenal e-Money Mandiri, Brizzi, TapCash, Flazz | Rekening dan dompet Bank DKI tidak punya identitas visual; JakCard tidak terbaca |
| 6 | Rencana Bulanan menyimpan `spent` dan `actual` sebagai isian manual; DESIGN.md menetapkan Transaksi sebagai satu-satunya jalur pencatatan buku kas | Rencana dan buku kas berjalan sendiri-sendiri; angka harus diketik dua kali |
| 7 | Anggaran, Tujuan, Transaksi Berulang, dan Rencana Bulanan adalah empat modul tanpa tautan data | Pengguna tidak melihat satu alur uang dari gaji sampai sisa |

**Simpulan.** Persoalannya bukan kekurangan fitur, melainkan tiga hal: (a)
penyajian Rencana Bulanan belum dirancang, (b) gerak belum menjadi sistem, dan
(c) modul perencanaan belum terhubung ke buku kas. Rencana di bawah menjawab
ketiganya tanpa menambah tujuan navigasi baru: **ARUS tetap referensi desain,
aplikasinya tetap Wallet.**

## 2. Arah desain

Watak: *tenang, presisi, hidup*. Profesional keuangan yang dipercaya, dengan
kelincahan yang akrab bagi generasi muda — bukan gamifikasi yang riuh.

- **Warna dan huruf** tetap mengikuti penyegaran 12 November (gading `#F5F6F0`,
  hutan `#0C6C58`, tinta `#192E28`, Plus Jakarta Sans). Tidak ada palet baru.
- **Angka sebagai tokoh utama.** Nominal besar, tabular, selalu bergerak lewat
  `AnimatedMoney` ketika nilainya berubah.
- **Satu gagasan visual khas: diagram alir.** Uang digambarkan mengalir dari
  Pendapatan → Tetap → Langganan → Tabungan → Dana → Sisa. Inilah makna harfiah
  "arus", dan menjadi tanda pengenal Wallet.
- **Kedalaman lewat lapisan, bukan bayangan tebal.** Kartu 20–24 px, garis
  rambut 1 px, sorot halus pada kartu yang aktif.

### 2.1 Sistem gerak (perluasan `app_motion.dart`)

| Lapis | Contoh | Durasi | Web |
|---|---|---|---|
| Umpan balik | tekan, hover, centang, sakelar | ≤ 200 ms | aktif |
| Perubahan nilai | angka bergulir, batang kemajuan tumbuh, cincin anggaran | 240–500 ms | aktif |
| Perubahan tata letak | kartu memuai menjadi rincian, kelompok membuka, urut ulang | 300–450 ms | aktif, hanya transform/opacity |
| Narasi | diagram alir tergambar, rekap tutup bulan | 700–1.200 ms, sekali per kunjungan | aktif, dapat dilewati |
| Perpindahan halaman | geser/pudar antarhalaman | 240 ms | tetap dimatikan (temuan 2) |

Kaidah: setiap animasi tunduk pada `AppMotion.reduced`; tidak ada gerak
berulang tanpa tombol jeda; anggaran kinerja web ≤ 16 ms per bingkai pada buku
kas besar, diukur sebelum dan sesudah. Primitif baru yang direncanakan:
`AnimatedProgress`, `FlowDiagram` (CustomPainter), `ExpandableCard`,
`CountBadge`, `SwipeAction`, `Skeleton`, dan umpan balik haptik pada HP.

### 2.2 Rencana Bulanan baru (inti pekerjaan)

Desktop (≥ 900 px) dua kolom; HP satu kolom dengan urutan yang sama.

1. **Kepala bulan** — pemilih bulan, status (rancangan / berjalan / ditutup),
   tombol "Salin ke templat".
2. **Kartu ringkasan** — pendapatan bersih, teralokasi, sisa atau defisit;
   angka bergulir, defisit berwarna tanah liat disertai ikon dan label.
3. **Diagram alir** — interaktif: ketuk satu cabang untuk menyaring daftar di
   bawahnya.
4. **Empat bagian** dalam `PillTabs` (HP) atau kartu berdampingan (desktop):
   - *Tetap* — daftar centang dengan gesek untuk menandai lunas.
   - *Langganan* — kartu per layanan: logo, harga IDR/USD, pajak, tanggal
     tagih, hitung mundur.
   - *Tabungan otomatis* — batang prioritas dan bobot yang dapat digeser;
     pembagian surplus dihitung ulang seketika.
   - *Dana bergulir* — saldo awal → alokasi → terpakai → saldo akhir, dengan
     batang bertingkat.
5. **Formulir** berpindah ke lembar bawah (HP) atau panel samping (desktop);
   daftar utama tidak lagi berisi kolom isian.

Aturan hitung, penyimpanan `personal_monthly_plans`, RLS, dan RPC berevisi
**tidak diubah**; ini pekerjaan penyajian di atas model yang sudah teruji.

## 3. Keterhubungan dengan aplikasi

Prinsip: perencana **membaca** buku kas dan **mengantar** ke formulir transaksi;
perencana tidak pernah menulis buku kas sendiri (DESIGN.md, "One Wallet
planner").

| Tautan | Cara kerja | Risiko kontrak |
|---|---|---|
| Rencana → Transaksi | Tombol "Catat" pada butir membuka `form_tx` dengan nominal, kategori, dan akun terisi; pengguna tetap menyimpan sendiri | Tidak ada |
| Transaksi → Rencana | Butir boleh ditautkan ke kategori; `spent` dihitung dari buku kas bulan itu, isian manual menjadi cadangan | Properti JSON tambahan (aditif) |
| Langganan ↔ Transaksi Berulang | Langganan dapat dibuat dari, atau menghasilkan, entri berulang; tanggal tagih satu sumber | Aditif |
| Tabungan ↔ Tujuan | Tabungan otomatis menunjuk Tujuan; kemajuan Tujuan tampil di kartu tabungan | Aditif |
| Dana bergulir ↔ Akun | Dana boleh menunjuk akun (misalnya dompet digital); saldo riil tampil sebagai pembanding | Aditif |
| Rencana ↔ Anggaran | Anggaran tetap batas belanja riil; Beranda menampilkan keduanya dalam satu kartu "Bulan ini" | Tidak ada |
| Beranda | Kartu "Aman dibelanjakan hari ini" = sisa rencana ÷ hari tersisa | Tidak ada |

## 4. Fitur tambahan

**Dompet digital dan Bank DKI**

- Kelompok akun baru **Dompet Digital** berikut pilihan cepat GoPay, OVO, DANA,
  LinkAja, ShopeePay, dan **JakOne Pay**; **Bank DKI / Bank Jakarta** masuk
  daftar bank. Nama ditampilkan sesuai merek yang berlaku; pemilik memastikan
  penamaan akhirnya.
- Logo hanya dipakai bila berkasnya sah digunakan; jika belum, tampil monogram
  berwarna merek melalui `AccountAvatar`.
- Templat **isi saldo** (transfer bank → dompet + biaya admin sebagai
  pengeluaran) agar saldo tidak selisih.
- **JakCard** lewat NFC bergantung pada dukungan paket `prepaidcard_reader`;
  dinilai terpisah, tidak dijanjikan pada tahap ini.
- Batas yang jujur: Wallet **tidak** menarik saldo otomatis dari bank atau
  dompet digital. Akses data rekening hanya terbuka bagi penyedia jasa
  pembayaran berizin melalui SNAP; saldo tetap dicatat pengguna.

**Fitur lain yang diusulkan** (urut manfaat):

1. Kalender tagihan dan pengingat H-1 untuk langganan dan transaksi berulang.
2. Simulasi "bagaimana jika": geser gaji atau bonus, lihat pembagian berubah.
3. Ritual tutup bulan: rekap beranimasi, dana bergulir berpindah ke bulan baru.
4. "Kilas Bulan": kartu ringkasan yang dapat dibagikan, nominal dapat
   disamarkan.
5. Palet perintah (Ctrl+K) di desktop dan catat cepat dari mana saja.
6. Lencana konsistensi mencatat — tenang, tanpa poin atau peringkat.

## 5. Cabang dan pembagian model

Setiap cabang berangkat dari `main`, menjadi satu PR draf, dan memakai
`[web-only]` selama belum ada paket native.

| Urut | Cabang | Isi | Model | Alasan |
|---|---|---|---|---|
| 0 | `claude/busy-mayer-fk7oqr` | Dokumen rencana ini | — | — |
| 1 | `desain/rancangan-rencana-bulanan` | Rancangan desktop + HP (HTML interaktif) untuk disepakati | Fable | Keputusan visual dan gerak |
| 2 | `desain/sistem-gerak` | Token dan primitif gerak baru + tes | Fable | Kurva, koreografi, kinerja CanvasKit |
| 3 | `fitur/rencana-bulanan-arus` | Pecah berkas 867 baris, tata letak baru, diagram alir | Fable (tampilan), Opus (pemecahan dan tes) | Gabungan desain dan refaktor berisiko |
| 4 | `fitur/dompet-digital` | Kelompok akun, pilihan cepat, monogram, templat isi saldo | Sonnet | Pola sudah ada, perubahan mekanis |
| 5 | `fitur/tautan-rencana` | Tautan pada bagian 3 | Opus | Menyentuh model data; perlu kehati-hatian |
| 6 | `fitur/kalender-pengingat` | Kalender tagihan, pengingat | Sonnet | Fitur terisolasi |
| 7 | `fitur/penyegaran-layar` | Menerapkan primitif gerak ke Beranda, Akun, Anggaran, Tujuan | Sonnet, ditinjau Fable | Penerapan berulang pola yang sudah jadi |
| 8 | `media/remotion` | Proyek Remotion terpisah di `motion/` | Fable | Animasi dan penyutradaraan |

Tahap 2, 4, dan 6 dapat berjalan sejajar setelah tahap 1 disepakati; tahap 3
menunggu tahap 2; tahap 5 menunggu tahap 3; tahap 7 paling akhir.

**Tentang Remotion.** Remotion menghasilkan video berbasis React, bukan
animasi di dalam aplikasi Flutter. Kegunaannya: video hero layar Selamat
Datang (sudah diputar `video_player`), klip tur fitur, dan materi Play Store.
Hasil render (MP4/WebM) masuk ke `assets/visual/`; proyeknya sendiri tidak
ikut build Flutter. Animasi di dalam aplikasi tetap dikerjakan dengan Flutter.

## 6. Gerbang uji dan batas

- Tiap PR: `flutter analyze`, tes terdampak, build web; tes tata letak pada
  360, 768, dan 1.280 px; tes mode gerak-dikurangi.
- Tangkapan layar desktop dan HP dilampirkan di PR sebelum digabung.
- Tidak mengubah autentikasi, buku kas, RLS, penandatanganan, atau versi
  native; tidak menerbitkan APK.
- Tidak ada nominal gaji atau anggaran pribadi di repositori; contoh memakai
  data tiruan.

## 7. Keputusan yang diperlukan dari pemilik

1. **Rujukan ARUS.** Sumber atau tangkapan layar ARUS tidak ada di repositori
   ini dan catatan Notion tidak terjangkau dari sesi ini. Mohon lampirkan agar
   rancangan tahap 1 setia pada rujukan.
2. **Kode kelompok akun baru.** "Dompet Digital" menambah kode yang ikut
   tersinkron. Aplikasi Android 1.4.3 akan menampilkannya sebagai "Lainnya"
   sampai diperbarui. Alternatif tanpa risiko: tetap kelompok "Bank" dengan
   penanda jenis. Rekomendasi: kode baru, karena laporan per kelompok menjadi
   benar.
3. **Tautan rencana** (tahap 5) menambah properti JSON; klien lama
   mengabaikannya. Perlu persetujuan karena menyentuh wilayah model data.
4. **Sasaran Remotion**: video hero, tur fitur, atau materi Play Store dahulu.

## Rujukan

- Undang-Undang Nomor 27 Tahun 2022 tentang Pelindungan Data Pribadi — dasar
  kerahasiaan data keuangan pengguna.
- Peraturan Bank Indonesia Nomor 23/6/PBI/2021 tentang Penyedia Jasa
  Pembayaran, dan Keputusan Gubernur Bank Indonesia Nomor 23/10/KEP.GBI/2021
  tentang Standar Nasional Open API Pembayaran (SNAP) — dasar batas "tanpa
  tarik saldo otomatis". Nomor regulasi perlu dicocokkan dengan naskah resmi
  sebelum dikutip di dalam aplikasi.
- W3C, *Web Content Accessibility Guidelines (WCAG) 2.2*, kriteria 2.2.2
  (Pause, Stop, Hide) dan 2.3.3 (Animation from Interactions).
- Google, *Material Design 3 — Motion* (easing dan durasi).
- `DESIGN.md`, `PRODUCT.md`, dan `docs/ROADMAP.md` pada repositori ini.
