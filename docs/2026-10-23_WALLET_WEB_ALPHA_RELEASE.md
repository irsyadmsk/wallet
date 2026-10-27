# Wallet 1.4.3+10403 — web live dan pengiriman Alpha

Tanggal: 23 Oktober 2026. Pemilik menjawab **“setuju”** untuk AAB pada track pengujian Play yang sama dan deploy web Wallet. Otorisasi ini dipakai hanya untuk kedua pengiriman tersebut. Tidak ada commit/push/PR/Actions, perubahan track/penguji, migrasi atau impor data baru.

## Hasil

| Kanal | Status terverifikasi |
|---|---|
| Web https://wallet.irsyads.com | **Live 1.4.3+10403**, versi Worker `e86a356e-5f09-496c-a667-16a8aee5dc35`, deployment `4e856400-3678-4b2c-a12d-d9474ced52fa`, aktif 100% |
| Google Play | AAB **10403 (1.4.3)** diterima dan diproses; rilis **5**, track **Pengujian tertutup – Alpha** (`4699684242169064715`) dikirim untuk review |
| Status Play setelah konfirmasi | **Perubahan yang sedang ditinjau**; pemeriksaan cepat Google masih berjalan. Console menyatakan perubahan diteruskan untuk review setelah pemeriksaan berhasil. Belum tersedia sebagai pembaruan HP yang dibuktikan |

Publikasi terkelola Play sudah nonaktif dan tidak diubah. Rilis mengatur 100% pada track Alpha yang sama setelah persetujuan Google; kanal produksi, negara dan daftar penguji tidak diubah. Pemeriksaan Play menunjukkan nol perangkat yang kehilangan dukungan pada seluruh faktor bentuk yang ditampilkan.

## Bukti

- AAB SHA256: `57499E06F9E168BDBB047C82D073BC7423ADCF1DDBF786B180BEE849DE691815`, sama dengan paket yang disetujui. Metadata Play: 10403/1.4.3, API24+, target36, tiga ABI. Catatan rilis Indonesia berasal dari `docs/play-store/whatsnew-id-ID.txt`.
- Web `version.json` produksi 1.4.3+10403. `main.dart.js` SHA256 `4233A3CFC3DF306236E2DD151F88977F07C2E7BB0484D567F57C8754258EAD95` cocok persis dengan build yang disetujui.
- Kesembilan aset merek produksi (lima font, tiga OFL, SOURCES.md) HTTP200 dan SHA256 cocok paket lokal.
- Browser produksi membuka dashboard menggunakan sesi yang sudah ada, kemudian Pengaturan. Versi 1.4.3, label Tinta Akademik dan kontrol tema baru terbaca; nol galat browser tertangkap. Tidak mengubah transaksi, preferensi, PIN atau data akun dalam pemeriksaan. Nominal/identitas keluarga dan tangkapan dashboard privat tidak disalin ke repo/laporan/helper.
- 13 tes terarah batch awal dan tujuh tambahan serta hasil analisis/build kandidat tetap menjadi bukti lokal; tidak diulang tanpa perubahan. Pembacaan UI produksi bukan bukti edit/simpan server, lintas perangkat atau native.

Receipt nonprivat di repo Irsyads: `scratch/wallet-release-20261023/` berisi authorization-preflight, before/after, log deploy, live-brand-assets, play-submission, manifest dan **play-submission.png**. Metadata rilis tercatat di `ops/releases/wallet-20261023-143.json`.

## Sumber daya dan pemulihan

Workers Free Active diperiksa langsung pada halaman Subscriptions. Biaya teramati/proyeksi periode berjalan $0. Snapshot batas pada pemeriksaan: requests hari ini 1/100.000, build40/3.000 menit. Angka itu snapshot, bukan saldo sesudah rilis. Direct upload menggunakan build lokal dan menambah **0 menit Actions/build remote**. Tidak memakai R2, layanan/model berbayar atau mengubah langganan.

Wrangler memerlukan refresh kredensial OAuth existing sesudah API401; whoami memperbaruinya, baca baseline lalu berhasil. Scope baru yang disarankan CLI tidak diminta/ditambahkan. Tidak ada retry deploy/upload karena timeout. Worker proxy yang dipakai adalah berkas persis dari rilis sebelumnya; source checkout hanya berbeda line ending. Ada23 aset baru/berubah dan123 sudah tersedia.

Pemulihan web sebelum pengiriman: versi Worker `c0dbdae2-28c5-4b98-b02b-2c77382790f6`, deployment `2a1596df-a475-4593-9a4b-9dcc12aeb074`, aplikasi1.4.2+2. Simpan dokumen pribadi/tabel yang ada; rollback frontend tidak menghapus data. Play masih memerlukan hasil pemeriksaan/review; jika ditolak, tinjau alasan sebelum paket berikutnya. Jangan kirim ulang rilis5 atau menaikkan nomor tanpa rekonsiliasi status. APK bertanda upload key bukan pengganti instalasi Google Play; jangan uninstall/clear storage/downgrade untuk memaksa update.

## Yang tetap terbuka

- Persetujuan/publikasi Google dan pembaruan fisik melalui Play, kemudian pemeriksaan data existing serta alur baru di HP.
- Edit/simpan akun nyata, persistensi lintas perangkat, dan penerimaan visual lengkap seluruh permukaan Wallet.
- Backlog Wallet di luar paket serta seluruh Studio/Toolkit/Portal/Quran/Hadits dan ekosistem lain tetap sesuai RENCANA_AKTIF. Keberhasilan subset ini bukan penyelesaian seluruh roadmap.

Sumber tetap uncommitted. Persetujuan rilis ini sudah dipakai; scope berikutnya mengikuti arahan pemilik dan kebijakan rilis.